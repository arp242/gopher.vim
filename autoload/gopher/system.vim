" buf.vim: Utilities for working with the external programs and the OS.

let s:root    = expand('<sfile>:p:h:h:h') " Root dir of this plugin.
let s:gotools = s:root . '/tools'         " Our Go tools.
let s:gobin   = s:gotools . '/bin'

" Command history; every item is a list with the exit code, time it took to run,
" command that was run, its output, and a boolean to signal it was run from
" #job(), in that order.
let s:history = []

" List of all tools we know about. The key is the binary name, the value is a
" 2-tuple with the full package name and a boolean to signal that go install has
" been run this Vim session.
let s:tools = {}

" Build s:tools from tools.go.
fun! s:init() abort
  for l:line in readfile(s:gotools . '/tools.go')
    if l:line !~# "^\t_ \""
      continue
    endif

    let l:line = split(l:line, '"')[1]
    let s:tools[fnamemodify(l:line, ':t')] = [l:line, 0]
  endfor
endfun
call s:init()

" Setup modules and install all tools.
fun! gopher#system#setup() abort
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

" Restore an environment variable back to its original value.
fun! gopher#system#restore_env(name, val) abort
  if a:val is -1
    exe printf('unlet $%s', a:name)
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
" async is a boolean flag to use the async API instead of system().
"
" done will be called when the command has finished with exit code and output as
" a string.
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

  let l:cmd = gopher#system#join(a:cmd)

  try
    let l:shell = &shell
    let l:shellredir = &shellredir
    let l:shellcmdflag = &shellcmdflag

    if gopher#has_debug('commands')
      let l:start = reltime()
    endif

    if !gopher#system#platform('win') && executable('/bin/sh')
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

  if gopher#has_debug('commands')
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
        \ 'cmd':    a:cmd,
        \ 'done':   a:done}

  if has('nvim')
    let l:state.closed = 1
    return jobstart(a:cmd, {
          \ 'on_stdout': function('s:j_out_cb',  [], l:state),
          \ 'on_stderr': function('s:j_out_cb',  [], l:state),
          \ 'on_exit':   function('s:j_exit_cb', [], l:state),
          \ })
  endif

  return job_start(a:cmd, {
        \ 'callback': function('s:j_out_cb',   [], l:state),
        \ 'exit_cb':  function('s:j_exit_cb',  [], l:state),
        \ 'close_cb': function('s:j_close_cb', [], l:state),
        \})
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
  return gopher#system#platform('win') ? ';' : ':'
endfun

" Check if this is the requested OS.
"
" Supports 'win', 'unix'.
fun! gopher#system#platform(n) abort
  if a:n is? 'win'
    return has('win16') || has('win32') || has('win64')
  elseif a:n is? 'unix'
    return has('unix')
  endif

  call gopher#error('gopher#system#platform: unknown parameter: ' . a:n)
endfun

" Download, compile and install a tool if needed.
fun! s:tool(name) abort
  if !has_key(s:tools, a:name)
    call gopher#error('unknown tool: ' . a:name)
    return ''
  endif

  let l:tool = s:tools[a:name]
  let l:bin = s:gobin . '/' . a:name

  " We already ran go install and there is a binary.
  if l:tool[1] && filereadable(l:bin)
    return a:name
  endif

  if !s:download(0)
    return
  endif

  try
    let l:old_gobin =  exists('$GOBIN')       ? $GOBIN       : -1
    let l:old_gomod =  exists('$GO111MODULE') ? $GO111MODULE : -1
    let l:old_gopath = exists('$GOPATH')      ? $GOPATH      : -1
    unlet $GOPATH
    let $GOBIN = s:gobin
    let $GO111MODULE = 'on'  " In case user set to 'off'

    let l:out = system(printf('cd %s && go install %s',
      \ shellescape(s:gotools), shellescape(l:tool[0])))
    if v:shell_error
      return gopher#error(l:out)
    endif

    " Record go install ran.
    let s:tools[a:name][1] = 1
  finally
    call gopher#system#restore_env('GOBIN', l:old_gobin)
    call gopher#system#restore_env('GO111MODULE', l:old_gomod)
    call gopher#system#restore_env('GOPATH', l:old_gopath)
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
    if !gopher#has_debug('commands')
      return
    endif

    " Full path is too noisy.
    let l:debug_cmd = a:cmd
    let l:debug_cmd[0] = substitute(a:cmd[0], "'", '', '')
    if l:debug_cmd[0][:len(s:gobin) - 1] is# s:gobin
      let l:debug_cmd[0] = 's:gobin/' . l:debug_cmd[0][len(s:gobin) + 1:]
    endif
    let s:history = insert(s:history, [
          \ a:exit,
          \ s:since(a:start),
          \ gopher#system#join(l:debug_cmd),
          \ a:out,
          \ !a:job], 0)
endfun

" Format time elapsed since start.
fun! s:since(start) abort
	return substitute(reltimestr(reltime(a:start)), '\v^\s*(\d+\.\d{0,3}).*', '\1', '')
endfun

" Join a list of commands to a string, escaping any shell meta characters.
fun! gopher#system#join(l, ...) abort
  try
    let l:save = &shellslash
    set noshellslash

    return join(map(copy(a:l), { i, v -> shellescape(l:v, a:0 > 0 ? a:1 : '') }), ' ')
  finally
    let &shellslash = l:save
  endtry
endfun

fun! s:j_exit_cb(job, exit, ...) abort dict
  let self.exit = a:exit

  if self.closed
    call gopher#system#_hist_(self.cmd, self.start, self.exit, self.out, 1)
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

  let self.out .= l:msg
endfun
