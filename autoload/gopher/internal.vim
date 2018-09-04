let s:root    = expand('<sfile>:p:h:h:h') " Root dir of this plugin.
let s:gotools = s:root . '/tools'         " Repo with vendored Go tools.
let s:gobin   = s:gotools . '/bin'

" Prepend our GOBIN to the path so that external tools/plugins use binaries from
" here.
if s:gobin !=# $PATH
  let $PATH = s:gobin . ':' . $PATH
endif

" List of all tools we know about. The key is the binary name, the value is a
" 2-tuple with the full package name a boolean to signal that go install has
" been run this Vim session.
let s:tools = {}

" Build s:tools with binary -> pkg mapping from tools.go.
fun! s:read_tools() abort
  for l:line in readfile(s:gotools . '/tools.go')
    if l:line !~# "^\t_ \""
      continue
    endif

    let l:line = split(l:line, '"')[1]
    let s:tools[fnamemodify(l:line, ':t')] = [l:line, 0]
  endfor
endfun
call s:read_tools()

" Echo a message to the screen and highlight it with the group in a:hi.
"
" The message can be a list or string; every line with be :echomsg'd separately.
fun! s:echo(msg, hi) abort
  let l:msg = []
  if type(a:msg) isnot v:t_list
    let l:msg = split(a:msg, "\n")
  else
    let l:msg = a:msg
  endif

  " Tabs display as ^I or <09>, so manually expand them.
  let l:msg = map(l:msg, 'substitute(v:val, "\t", "        ", "")')

  exe 'echohl ' . a:hi
  for line in l:msg
    echom 'gopher.vim: ' . line
  endfor
  echohl None
endfun

fun! gopher#internal#error(msg) abort
  call s:echo(a:msg, 'ErrorMsg')
endfun

fun! gopher#internal#info(msg) abort
  call s:echo(a:msg, 'Debug')
endfun

" Install all tools.
fun! gopher#internal#install_all() abort
  if !s:vendor(1)
    return
  endif

  for l:tool in keys(s:tools)
    call s:tool(l:tool)
  endfor
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
    call gopher#internal#restore_env('GOBIN', l:old_gobin)
    call gopher#internal#restore_env('GO111MODULE', l:old_gomod)
  endtry

  return l:bin
endfun

fun! s:escape_single_quote(s)
  return "'" . substitute(a:s, "'", "' . \"'\" . '", '') . "'"
endfun

" Restore an environment variable back its original value.
fun! gopher#internal#restore_env(name, val)
  if a:val isnot? ''
    exe printf('let $%s = %s', a:name, s:escape_single_quote(a:val))
  else
    exe printf('unlet $%s', a:name)
  endif
endfun

let s:ran_mod_vendor = 0
" Run go mod vendor; only need to run this once.
fun! s:vendor(force) abort
  if s:ran_mod_vendor && !a:force
    return 1
  endif

  " Assume that the existence of the directory means it's valid.
  " TODO: we need to run this again after vim-go updated; I'm not sure what the
  " best/fastest way to do that is; maybe just run it once per Vim instance?
  if isdirectory(s:gotools . '/vendor') && !a:force
    let s:ran_mod_vendor = 1
    return 1
  endif

  call gopher#internal#info('running "go mod vendor"; this may take a few seconds')
  let l:out = system(printf('cd %s && go mod vendor', s:gotools))
  if v:shell_error
    echoerr l:out
    return 0
  endif

  " Clear message.
  redraw!

  let s:ran_mod_vendor = 1
  return 1
endfun

" Run a vendored Go tool.
fun! gopher#internal#tool(cmd, ...) abort
  if type(a:cmd) isnot v:t_list
    call gopher#internal#error('must pass a list')
    return
  endif

  let l:bin = s:tool(a:cmd[0])
  if l:bin is? ''
    return ['', 1]
  endif

  return gopher#internal#system([l:bin] + a:cmd[1:])
endfun

" Shell command history; every item is a list with the exit code, time it took
" to run, command that was run, and its output, in that order.
let s:shell_history = []

" Run "cmd" in the shell. cmd must be a list, one argument per item. Every list
" entry will be automatically shell-escaped
"
" Every other argument is passed to stdin.
fun! gopher#internal#system(cmd, ...) abort
  if type(a:cmd) isnot v:t_list
    call gopher#internal#error('must pass a list')
    return
  endif

  let l:cmd = s:join_shell(a:cmd)

  try
    let l:shell = &shell
    let l:shellredir = &shellredir

    if gopher#config#has_debug('shell')
      let l:start = reltime()
    endif

    let l:out = call('system', [l:cmd] + a:000)
  finally
    let &shell = l:shell
    let &shellredir = l:shellredir
  endtry

  " Remove trailing newline from output; it's rarely useful, and often annoying.
  if l:out[-1:] is# "\n"
    let l:out = l:out[:-2]
  endif

  if gopher#config#has_debug('shell')
    " Full path is too noisy.
    let l:debug_cmd = a:cmd
    let l:debug_cmd[0] = fnamemodify(l:debug_cmd[0], ':t')
    let s:shell_history = add(s:shell_history, [
          \ v:shell_error,
          \ s:since(l:start),
          \ s:join_shell(l:debug_cmd),
          \ l:out])
  endif

  return [l:out, v:shell_error]
endfun

" Format time elapsed since start.
fun! s:since(start) abort
	return substitute(reltimestr(reltime(a:start)), '\v^\s*(\d+\.\d{0,3}).*', '\1', '')
endfun

fun s:join_shell(l, ...) abort
  try
    let l:save = &shellslash
    set noshellslash

    return join(map(copy(a:l), { i, v -> shellescape(l:v, a:0 > 0 ? a:1 : '') }), ' ')
  finally
    let &shellslash = l:save
  endtry
endfun

" Returns the byte offset for the cursor.
"
" If the first argument is non-blank it will return filename:#offset
fun! gopher#internal#cursor_offset(...) abort
  let l:o = line2byte(line('.')) + (col('.') - 2)

  if len(a:000) > 0 && a:000[0]
    return printf('%s:#%d', expand('%:p'), l:o)
  endif

  return l:o
endfunction

" Get all lines in the buffer as a a list.
fun! gopher#internal#lines() abort
  let l:buf = getline(1, '$')

  if &l:fileformat is? 'dos'
    " TODO: line2byte() depend on 'fileformat' option, so if fileformat is
    " 'dos', 'buf' must include '\r'.
    let l:buf = map(l:buf, 'v:val . "\r"')
  endif
  return l:buf
endfun

" Write unsaved buffer to a temp file when modified, so tools that operate on
" files can use that.
"
" Don't forget to delete the tmp file!
fun! gopher#internal#tmpmod()
  if &modified
    let l:tmp = tempname()
    call writefile(gopher#internal#lines(), l:tmp)
    return [l:tmp, l:tmp]
  endif

  return [expand('%:p'), '']
endfun

fun! s:indent(out)
  let l:out = a:out
  if type(l:out) is v:t_string
    let l:out = split(l:out, "\n")
  endif

  return map(l:out, { i, v -> '    ' . l:v })
endfun

fun! gopher#internal#state(to_clipboard)
  let l:state = []

  " Disable 'shell' debug flag, as this will add a bunch of commands to history,
  " which is not very useful.
  let l:add_debug = 0
  let l:i = index(get(g:, 'gopher_debug', []), 'shell')
  if l:i > -1
    call remove(g:gopher_debug, l:i)
    let l:add_debug = 1
  endif

  try
    " Vim version.
    let l:state = add(l:state, 'VERSION')
    let l:state += s:indent(split(execute('version'), "\n")[:1])

    " Go version.
    let [l:out, l:err] = gopher#internal#system(['go', 'version'])
    if l:err
      let l:state = add(l:state, '    ERROR go version exit ' . l:err)
    endif
    let l:state += s:indent(l:out)

    " GOPATH and GOROOT.
    let [l:out, l:err] = gopher#internal#system(['go', 'env', 'GOPATH', 'GOROOT'])
    if l:err
      let l:state = add(l:state, '    ERROR go env exit ' . l:err)
      let l:state += s:indent(l:out)
    else
      let l:out = substitute('GOPATH=' . l:out, "\n", "\nGOROOT=", '')
      let l:state += s:indent(l:out)
    endif

    " gopher.vim version.
    let [l:out, l:err] = gopher#internal#system(['git', '-C', s:root, 'log', '--format=gopher.vim version %h %ci (%cr) %s', '-n1'])
    if l:err
      let l:state = add(l:state, '    ERROR git log')
    endif
    let l:state += s:indent(l:out)
    let l:state = add(l:state, ' ')

    " List all config variables.
    let l:state = add(l:state, 'VARIABLES')
    let l:state += s:indent(filter(split(execute('let'), "\n"), { i, v -> l:v =~# '^gopher#' }))
    let l:state = add(l:state, ' ')

    " List shell history (if any).
    let l:state = add(l:state, 'SHELL HISTORY')
    for l:h in s:shell_history
      let l:state = add(l:state, '    $ ' . l:h[2])
      let l:state = add(l:state, printf('    exit %s; took %ss', l:h[0], l:h[1]))
      let l:state += s:indent(l:h[3])
      let l:state = add(l:state, ' ')
    endfor
  finally
    if l:add_debug
      let g:gopher_debug = add(g:gopher_debug, 'shell')
    endif
  endtry

  if a:to_clipboard
    let @+ = join(l:state, "\n")
  else
    for l:line in l:state
      echom l:line
    endfor
  endif
endfun
