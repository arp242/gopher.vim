" system.vim: Utilities for working with the external programs and the OS.

let s:root    = expand('<sfile>:p:h:h:h') " Root dir of this plugin.
let s:gotools = s:root . '/tools'         " Our Go tools.
let s:gobin   = s:gotools . '/bin'
let s:jobs    = []                        " List of running jobs.

" Command history; every item is a list with the exit code, time it took to run,
" command that was run, its output, and a boolean to signal it was run from
" #job(), in that order.
let s:history = []

" List of all tools we know about. The key is the binary name, the value is a
" 2-tuple with the full package name and a boolean to signal that go install has
" been run this Vim session.
let s:tools = {}

" Build s:tools from tools.go; this is run when this file is loaded.
fun! s:init() abort
  for l:line in readfile(s:gotools . '/tools.go')
    if l:line !~# "^\t_ \""
      continue
    endif

    let l:line = split(l:line, '"')[1]
    let s:tools[fnamemodify(l:line, ':t')] = [l:line, 0]
  endfor

  " Make sure gopls is available, otherwise external LSP servers are going to
  " error out.
  if !executable('gopls')
    call gopher#info('installing gopls; this may take a minute')
    call s:tool('gopls')
  endif
  " goimports is similarly useful, but not directly referenced by gopher.vim
  if !executable('goimports')
    call gopher#info('installing goimports; this may take a minute')
    call s:tool('goimports')
  endif
endfun

" Setup modules and install all tools.
fun! gopher#system#setup() abort
  call s:setup_debug('running with g:gopher_setup flags: %s', get(g:, 'gopher_setup', []))

  if !s:download(1)
    return
  endif

  for l:tool in keys(s:tools)
    call s:tool(l:tool)
  endfor
endfun

" Get command history (only populated if 'commands' is in the g:gopher_debug)
" variable. Note that the list is reversed (new entries are prepended, not
" appended).
fun! gopher#system#history() abort
  return s:history
endfun

" Clear command history.
fun! gopher#system#clear_history() abort
  let s:history = []
endfun

" Get a list of currently running jobs. Use job_info() to get more information
" about a job.
fun! gopher#system#jobs() abort
  return s:jobs
endfun

" Restore an environment variable back to its original value.
fun! gopher#system#restore_env(name, val) abort
  if a:val is -1
    if has('patch-8.0.1832')
      exe printf('unlet $%s', a:name)
    else
      " Best effort for older Vim.
      exe printf('let $%s = ""', a:name)
    endif
  else
    exe printf('let $%s = %s', a:name, s:escape_single_quote(a:val))
  endif
endfun

" Write unsaved buffer to a temp file when modified, so tools that operate on
" files can use that.
"
" The first return value is either the tmp file or the full path to the original
" file (if not modified), the second return value signals that this is a tmp
" file.
"
" Don't forget to delete the tmp file!
fun! gopher#system#tmpmod() abort
  if &modified
    let l:tmp = tempname()
    call writefile(gopher#buf#lines(), l:tmp)
    return [l:tmp, 1]
  endif

  return [expand('%:p'), 0]
endfun

" Format the current buffer as an 'overlay archive':
" https://godoc.org/golang.org/x/tools/go/buildutil#ParseOverlayArchive
fun! gopher#system#archive() abort
  return printf("%s\n%d\n%s",
          \ expand('%'),
          \ line2byte('$') + len(getline('$')) - 1,
          \ join(gopher#buf#lines(), "\n"))
endfun

" Run a known Go tool.
fun! gopher#system#tool(cmd, ...) abort
  if type(a:cmd) isnot v:t_list
    return gopher#error('gopher#system#tool: must pass a list')
  endif
  if len(a:000) > 1
    return gopher#error('gopher#system#tool: can only pass one optional argument')
  endif

  let l:bin = s:tool(a:cmd[0])
  if l:bin is? ''
    return [printf('unknown tool: "%s"', a:cmd[0]), 1]
  endif

  return call('gopher#system#run', [[l:bin] + a:cmd[1:]] + a:000)
endfun

" Run a known Go tool in the background.
fun! gopher#system#tool_job(done, cmd) abort
  if type(a:cmd) isnot v:t_list
    return gopher#error('must pass a list')
  endif

  let l:bin = s:tool(a:cmd[0])
  if l:bin is? ''
    call go#internal#error('unknown tool: "%s"')
  endif

  call gopher#system#job(a:done, [l:bin] + a:cmd[1:])
endfun

" Run an external command.
"
" cmd must be a list, one argument per item. Every list entry will be
" automatically shell-escaped
"
" An optional second argument is passed to stdin.
fun! gopher#system#run(cmd, ...) abort
  if type(a:cmd) isnot v:t_list
    return gopher#error('gopher#system#run: must pass a list')
  endif
  if len(a:000) > 1
    return gopher#error('gopher#system#run: can only pass one optional argument')
  endif

  let l:cmd = gopher#system#join(gopher#system#sanitize_cmd(a:cmd))

  try
    let l:shell = &shell
    let l:shellredir = &shellredir
    let l:shellcmdflag = &shellcmdflag
    let l:start = reltime()

    if !has('win32') && executable('/bin/sh')
      set shell=/bin/sh shellredir=>%s\ 2>&1 shellcmdflag=-c
    endif

    let l:out = call('system', [l:cmd] + a:000)
    let l:err = v:shell_error
  finally
    let &shell = l:shell
    let &shellredir = l:shellredir
    let &shellcmdflag = l:shellcmdflag
  endtry

  " Remove trailing newline from output; it's rarely useful, and often annoying.
  if l:out[-1:] is# "\n"
    let l:out = l:out[:-2]
  endif

  " Hack to prevent :GoDiag from adding commands.
  if a:0 is 0 || a:1 isnot# 'NO_HISTORY'
    call gopher#system#_hist_(a:cmd, l:start, v:shell_error, l:out, 0)
  endif
  return [l:out, l:err]
endfun

" Start a simple async job.
"
" cmd    Command as list.
" done   Callback function, called with the arguments:
"          exit  exit code
"          out   stdout and stderr output as string, interleaved in correct
"                order (hopefully).
"
" TODO: Don't run multiple jobs that modify the buffer at the same time. For
" some tools (like gorename) we need a global lock.
fun! gopher#system#job(done, cmd) abort
  if type(a:cmd) isnot v:t_list
    return gopher#error('must pass a list')
  endif

  let l:state = {
        \ 'out':    '',
        \ 'closed': 0,
        \ 'exit':   -1,
        \ 'start':  reltime(),
        \ 'cmd':    gopher#system#sanitize_cmd(a:cmd),
        \ 'done':   a:done}

  if has('nvim')
    let l:state.closed = 1
    return jobstart(a:cmd, {
          \ 'on_stdout': function('s:j_out_cb',  [], l:state),
          \ 'on_stderr': function('s:j_out_cb',  [], l:state),
          \ 'on_exit':   function('s:j_exit_cb', [], l:state),
          \ })
  endif

  let l:job = job_start(a:cmd, {
        \ 'callback': function('s:j_out_cb',   [], l:state),
        \ 'exit_cb':  function('s:j_exit_cb',  [], l:state),
        \ 'close_cb': function('s:j_close_cb', [], l:state),
        \})

  call add(s:jobs, l:job)
  return l:job
endfun

" Wait for a job to finish. Note that the exit_cb or close_cb may still be
" running after this returns!
" It will return the job status ("fail" or "dead").
fun! gopher#system#job_wait(job) abort
  if has('nvim')
    return jobwait(a:job) is 0 ? 'dead' : 'fail'
  endif

  while 1
    let l:s = job_status(a:job)
    if l:s isnot# 'run'
      return l:s
    end
    sleep 50m
  endwhile
endfun

" Get the path separator for this platform.
fun! gopher#system#pathsep() abort
  return has('win32') ? ';' : ':'
endfun

" Download, compile and install a tool if needed.
fun! s:tool(name) abort
  if !has_key(s:tools, a:name)
    call gopher#error('unknown tool: ' . a:name)
    return ''
  endif

  if index(get(g:, 'gopher_setup', []), 'no-auto-install') > -1
    return a:name
  endif

  let l:no_vendor_gobin = index(get(g:, 'gopher_setup', []), 'no-vendor-gobin') > -1
  let l:tool            = s:tools[a:name]
  let l:bin             = s:gobin . '/' . a:name

  if l:tool[1]
    if l:no_vendor_gobin && exepath(a:name)
      call s:setup_debug('%s: already in PATH; not doing anything', a:name)
      return a:name
    endif
    if !l:no_vendor_gobin && filereadable(l:bin)
      call s:setup_debug('%s: %s already exists; not doing anything', a:name, l:bin)
      return a:name
    endif
  endif

  if !s:download(0)
    return
  endif

  try
    if !l:no_vendor_gobin
      let l:old_gobin = exists('$GOBIN') ? $GOBIN : -1
      let $GOBIN = s:gobin
    endif

    let l:old_gomod =  exists('$GO111MODULE') ? $GO111MODULE : -1
    let $GO111MODULE = 'on'  " In case user set to 'off'

    call s:setup_debug('%s: running go install %s', a:name, l:tool[0])

    let l:out = system(printf('cd %s && go install %s',
      \ shellescape(s:gotools), shellescape(l:tool[0])))
    if v:shell_error
      return gopher#error(l:out)
    endif

    " Record go install ran.
    let s:tools[a:name][1] = 1
  finally
    if !l:no_vendor_gobin
      call gopher#system#restore_env('GOBIN', l:old_gobin)
    endif
    call gopher#system#restore_env('GO111MODULE', l:old_gomod)
  endtry

  return a:name
endfun

fun! s:escape_single_quote(s) abort
  return "'" . substitute(a:s, "'", "' . \"'\" . '", '') . "'"
endfun

let s:ran_mod_download = 0
" Run go mod download; only need to run this once per Vim session.
fun! s:download(force) abort
  if s:ran_mod_download && !a:force
    return 1
  endif

  call gopher#info('running "go mod download"; this may take a few seconds')
  let l:out = system(printf('cd %s && go mod download', s:gotools))
  if v:shell_error
    call gopher#error(l:out)
    return 0
  endif

  " Clear message.
  redraw!

  let s:ran_mod_download = 1
  return 1
endfun

" Add item to history.
" TODO: add information about stdin too.
fun! gopher#system#_hist_(cmd, start, exit, out, job) abort
    " Full path is too noisy.
    let l:debug_cmd = a:cmd
    let l:debug_cmd[0] = substitute(a:cmd[0], "'", '', '')
    if l:debug_cmd[0][:len(s:gobin) - 1] is# s:gobin
      let l:debug_cmd[0] = 's:gobin/' . l:debug_cmd[0][len(s:gobin) + 1:]
    endif

    let l:out = a:out
    if !gopher#has_debug('commands')
      if len(l:out) > 100
        let l:out = l:out[:100] . '…'
      endif
      let s:history = s:history[:3]
    endif

    call insert(s:history, [
          \ a:exit,
          \ s:since(a:start),
          \ gopher#system#join(l:debug_cmd),
          \ l:out,
          \ !a:job], 0)
endfun

" Format time elapsed since start.
fun! s:since(start) abort
	return substitute(reltimestr(reltime(a:start)), '\v^\s*(\d+\.\d{0,3}).*', '\1', '')
endfun

" Join a list of commands to a string, escaping any shell meta characters.
fun! gopher#system#join(l, ...) abort
  try
    if has('+shellslash')  " NeoVim will error setting shellslash on non-Windows
      let l:save = &shellslash
      set noshellslash
    endif

    let l:l = filter(copy(a:l), {_, v -> v isnot v:null })
    return join(map(l:l, {_, v -> shellescape(l:v, a:0 > 0 ? a:1 : '') }), ' ')
  finally
    if exists('+shellslash')
      let &shellslash = l:save
    endif
  endtry
endfun

" Remove v:null from the command, makes it easier to build commands:
"
"   gopher#system#run(['gosodoff', (a:error ? '-errcheck' : v:null)])
"
" Without the filter an empty string would be passed.
fun! gopher#system#sanitize_cmd(cmd) abort
  return filter(a:cmd, {_, v -> l:v isnot v:null})
endfun

fun! s:j_exit_cb(job, exit, ...) abort dict
  let self.exit = a:exit

  if self.closed
    call gopher#system#_hist_(self.cmd, self.start, self.exit, self.out, 1)
    for l:i in range(0, len(s:jobs) - 1)
      if s:jobs[l:i] is a:job
        call remove(s:jobs, l:i)
        break
      endif
    endfor

    call self.done(self.exit, self.out)
  endif
endfun

fun! s:j_close_cb(ch) abort dict
  let self.closed = 1

  if self.exit > -1
    call gopher#system#_hist_(self.cmd, self.start, self.exit, self.out, 1)
    call self.done(self.exit, self.out)
  endif
endfun

fun! s:j_out_cb(ch, msg, ...) abort dict
  let l:msg = a:msg
  if type(l:msg) is v:t_list
    let l:msg = join(l:msg, "\n")
  endif

  " TODO: this is probably wrong, at least on Neovim. It assumes that every
  " "msg" is a line.
  let self.out .= l:msg . "\n"
endfun

let s:writetick = 0
augroup gopher.vim-cache
  au!
  au BufWritePost *.go let s:writetick += 1
augroup end
let s:cache = {}

" Store data in the cache.
fun! gopher#system#store_cache(val, name, ...) abort
  let [l:diff, _] = ['git', 'diff']
  let s:cache[a:name . join(a:000)] = [[s:writetick, localtime(), sha256(l:diff)], a:val]
endfun

" Retrieve data from the cache.
fun! gopher#system#cache(name, ...) abort
  let l:k = a:name . join(a:000)
  let l:c = get(s:cache, l:k, v:null)
  if l:c is v:null
    return [v:null, v:false]
  endif

  " Cache expiry, in order of cheapest to most expensive:
  "
  " - Any open buffer changed.
  "
  " - More than a minute ago. Main goal is so that people typing ':GoImport
  "   <Tab>' have bette response times the second and third time they press Tab.
  "
  " - Files on disk changes: 'git diff | sha256sum'; it takes about 0.01s on my
  "   system with a medium repo (much faster than go list etc.)
  if s:writetick > l:c[0][0]
    let s:cache[l:k] = v:null
    return [v:null, v:false]
  elseif localtime() > l:c[0][1] + 60  " Cache for 1 minute only.
    let s:cache[l:k] = v:null
    return [v:null, v:false]
  else
    let [l:diff, _] = ['git', 'diff']
    if sha256(l:diff) isnot# l:c[0][2]
      let s:cache[l:k] = v:null
      return [v:null, v:false]
    endif
  endif

  return [l:c[1], v:true]
endfun

fun! s:setup_debug(msg, ...) abort
  if gopher#has_debug('setup')
    call call('gopher#info', ['setup: ' . a:msg] + a:000)
  endif
endfun

" Get the closest directory with this name up the tree from the current buffer's
" path.
"
" /a/b/c   c → /a/b/c
" /a/b/c   a → /a
" /a/b/c   x → (empty string)
fun! gopher#system#closest(name) abort
  let l:dir = expand('%:p:h')

  while 1
   " TODO: len() check is for Windows; not sure how that's represented.
    if l:dir is# '/' || len(l:dir) <= 4
      return ''
    endif
    if fnamemodify(l:dir, ':t') is# a:name
      return l:dir
    endif
    let l:dir = fnamemodify(l:dir, ':h')
  endwhile
endfun


call s:init()  " At end so entire file is parsed.
