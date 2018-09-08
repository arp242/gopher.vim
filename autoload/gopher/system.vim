let s:root    = expand('<sfile>:p:h:h:h') " Root dir of this plugin.
let s:gotools = s:root . '/tools'         " Vendored Go tools.
let s:gobin   = s:gotools . '/bin'

" Command history; every item is a list with the exit code, time it took to run,
" command that was run, its output, and a boolean to signal it was run from
" #job(), in that order.
let s:history = []

" Prepend our GOBIN to the path so that external tools/plugins use binaries from
" here.
if s:gobin !~# $PATH
  let $PATH = s:gobin . ':' . $PATH
endif

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

" Setup vendor and install all tools.
fun! gopher#system#setup() abort
  if !s:vendor(1)
    return
  endif

  for l:tool in keys(s:tools)
    call s:tool(l:tool)
  endfor
endfun

" Get command history (only populated if 'commands' is in the g:gopher_debug)
" variable.
fun! gopher#system#history() abort
  return s:history
endfun

" Restore an environment variable back to its original value.
fun! gopher#system#restore_env(name, val) abort
  if a:val isnot? ''
    exe printf('let $%s = %s', a:name, s:escape_single_quote(a:val))
  else
    exe printf('unlet $%s', a:name)
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
    call writefile(gopher#internal#lines(), l:tmp)
    return [l:tmp, 1]
  endif

  return [expand('%:p'), 0]
endfun

" Run a vendored Go tool.
fun! gopher#system#tool(cmd, ...) abort
  if type(a:cmd) isnot v:t_list
    call gopher#internal#error('gopher#system#tool: must pass a list')
    return
  endif
  if len(a:000) > 1
    call gopher#internal#error('gopher#system#tool: can only pass one optional argument')
    return
  endif

  let l:bin = s:tool(a:cmd[0])
  if l:bin is? ''
    return [printf('unknown tool: "%s"', a:cmd[0]), 1]
  endif

  "return gopher#system#run([l:bin] + a:cmd[1:])
  return call('gopher#system#run', [[l:bin] + a:cmd[1:]] + a:000)
endfun

" Run a vendored Go tool in the background.
fun! gopher#system#tool_job(done, cmd) abort
  if type(a:cmd) isnot v:t_list
    call gopher#internal#error('must pass a list')
    return
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
    call gopher#internal#error('gopher#system#run: must pass a list')
    return
  endif
  if len(a:000) > 1
    call gopher#internal#error('gopher#system#run: can only pass one optional argument')
    return
  endif

  let l:cmd = s:join_shell(a:cmd)

  try
    let l:shell = &shell
    let l:shellredir = &shellredir

    if gopher#config#has_debug('commands')
      let l:start = reltime()
    endif

    let l:out = call('system', [l:cmd] + a:000)
    let l:err = v:shell_error
  finally
    let &shell = l:shell
    let &shellredir = l:shellredir
  endtry

  " Remove trailing newline from output; it's rarely useful, and often annoying.
  if l:out[-1:] is# "\n"
    let l:out = l:out[:-2]
  endif

  if gopher#config#has_debug('commands')
    call s:hist(a:cmd, l:start, v:shell_error, l:out, 0)
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
" TODO: Neovim
fun! gopher#system#job(done, cmd) abort
  if type(a:cmd) isnot v:t_list
    call gopher#internal#error('must pass a list')
    return
  endif

  let l:state = {
        \ 'out':    '',
        \ 'closed': 0,
        \ 'exit':   -1,
        \ 'start':  reltime(),
        \ 'cmd':    a:cmd,
        \ 'done':   a:done,
        \ }

  return job_start(a:cmd, {
        \ 'exit_cb':  function('s:j_exit_cb', [], l:state),
        \ 'out_cb':   function('s:j_out_cb', [], l:state),
        \ 'err_cb':   function('s:j_err_cb', [], l:state),
        \ 'close_cb': function('s:j_close_cb', [], l:state),
        \})
endfun

" Get the full path to a tool name; download, compile and install it from the
" go.mod file if needed.
fun! s:tool(name) abort
  if !has_key(s:tools, a:name)
    call gopher#internal#error('unknown tool: ' . a:name)
    return ''
  endif

  let l:tool = s:tools[a:name]
  let l:bin = s:gobin . '/' . a:name

  " We already ran go install and there is a binary.
  if l:tool[1] && filereadable(l:bin)
    return l:bin
  endif

  if !s:vendor(0)
    return
  endif

  try
    let l:old_gobin = $GOBIN
    let l:old_gomod = $GO111MODULE
    let $GOBIN = s:gobin
    let $GO111MODULE = 'on'  " In case user set to 'off'

    let l:out = system(printf('cd %s && go install ./vendor/%s',
      \ shellescape(s:gotools), shellescape(l:tool[0])))
    if v:shell_error
      call gopher#internal#error(l:out)
      return
    endif

    " Record go install ran.
    let s:tools[a:name][1] = 1
  finally
    call gopher#system#restore_env('GOBIN', l:old_gobin)
    call gopher#system#restore_env('GO111MODULE', l:old_gomod)
  endtry

  return l:bin
endfun

fun! s:escape_single_quote(s) abort
  return "'" . substitute(a:s, "'", "' . \"'\" . '", '') . "'"
endfun

let s:ran_mod_vendor = 0
" Run go mod vendor; only need to run this once per Vim session.
fun! s:vendor(force) abort
  if s:ran_mod_vendor && !a:force
    return 1
  endif

  let l:msg_shown = 0
  " Only show on initial setup; too much flashing otherwise!
  if !isdirectory(s:gotools . '/vendor')
    let l:msg_shown = 1
    call gopher#internal#info('running "go mod vendor"; this may take a few seconds')
  endif

  let l:out = system(printf('cd %s && go mod vendor', s:gotools))
  if v:shell_error
    echoerr l:out
    return 0
  endif

  if l:msg_shown
    redraw!
  endif

  let s:ran_mod_vendor = 1
  return 1
endfun

" Add item to history.
" TODO: add information about stdin too.
fun! s:hist(cmd, start, exit, out, job) abort
    if !gopher#config#has_debug('commands')
      return
    endif

    " Full path is too noisy.
    let l:debug_cmd = a:cmd
    let l:debug_cmd[0] = substitute(a:cmd[0], "'", '', '')
    if l:debug_cmd[0][:len(s:gobin) - 1] is# s:gobin
      let l:debug_cmd[0] = 's:gobin/' . l:debug_cmd[0][len(s:gobin) + 1:]
    endif
    let s:history = add(s:history, [
          \ a:exit,
          \ s:since(a:start),
          \ s:join_shell(l:debug_cmd),
          \ a:out,
          \ !a:job])
endfun

" Format time elapsed since start.
fun! s:since(start) abort
	return substitute(reltimestr(reltime(a:start)), '\v^\s*(\d+\.\d{0,3}).*', '\1', '')
endfun

fun! s:join_shell(l, ...) abort
  try
    let l:save = &shellslash
    set noshellslash

    return join(map(copy(a:l), { i, v -> shellescape(l:v, a:0 > 0 ? a:1 : '') }), ' ')
  finally
    let &shellslash = l:save
  endtry
endfun

fun! s:j_close_cb(ch) abort dict
  let self.closed = 1

  if self.exit > -1
    call s:hist(self.cmd, self.start, self.exit, self.out, 1)
    call self.done(self.exit, self.out)
  endif
endfun

fun! s:j_exit_cb(job, exit) abort dict
  let self.exit = a:exit

  if self.closed
    call s:hist(self.cmd, self.start, self.exit, self.out, 1)
    call self.done(self.exit, self.out)
  endif
endfun

fun! s:j_out_cb(ch, msg) abort dict
  let self.out .= a:msg
endfun

fun! s:j_err_cb(ch, msg) abort dict
  let self.out .= a:msg
endfun
