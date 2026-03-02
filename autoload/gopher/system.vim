" system.vim: Utilities for working with the external programs and the OS.

let s:jobs = []  " List of running jobs.

" Command history; every item is a list with the exit code, time it took to run,
" command that was run, its output, and a boolean to signal it was run from
" #job(), in that order.
let s:history = []

let s:tools = [
    \ 'arp242.net/goimport@latest',
    \ 'zgo.at/gosodoff@latest',
    \ 'github.com/davidrjenni/reftools/cmd/fillstruct@latest',
    \ 'github.com/fatih/gomodifytags@latest',
    \ 'github.com/fatih/motion@latest',
    \ 'github.com/josharian/impl@latest',
    \ 'golang.org/x/tools/cmd/goimports@latest',
    \ 'golang.org/x/tools/gopls@latest',
\ ]

" Install all tools
fun! gopher#system#setup() abort
  for tool in s:tools
    call gopher#info('running go install %s', tool)
    let [out, err] = gopher#system#run(['go', 'install', tool])
    if err
      return gopher#error(out)
    endif
  endfor

  redraw! " Clear message.
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

  let bin = exepath(a:cmd[0])
  if bin == ''
    return gopher#error('"%s" not found in $PATH (maybe run :GoSetup?)', a:cmd)
  endif
  return call('gopher#system#run', [[l:bin] + a:cmd[1:]] + a:000)
endfun

" Run a known Go tool in the background.
fun! gopher#system#tool_job(done, cmd) abort
  if type(a:cmd) isnot v:t_list
    return gopher#error('must pass a list')
  endif

  let bin = exepath(a:cmd[0])
  if bin == ''
    return gopher#error('"%s" not found in $PATH (maybe run :GoSetup?)', a:cmd)
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
" TODO: Don't run multiple jobs that modify the buffer at the same time.
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

fun! s:escape_single_quote(s) abort
  return "'" . substitute(a:s, "'", "' . \"'\" . '", '') . "'"
endfun

" Add item to history.
" TODO: add information about stdin too.
fun! gopher#system#_hist_(cmd, start, exit, out, job) abort
    " Full path is too noisy.
    let l:debug_cmd = a:cmd
    let l:debug_cmd[0] = substitute(a:cmd[0], "'", '', '')
    "if l:debug_cmd[0][:len(s:gobin) - 1] is# s:gobin
    "  let l:debug_cmd[0] = 's:gobin/' . l:debug_cmd[0][len(s:gobin) + 1:]
    "endif

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
