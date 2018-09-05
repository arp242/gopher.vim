let s:root = expand('<sfile>:p:h:h:h') " Root dir of this plugin.

" Output an error message to the screen. The message can be either a list or a
" string; every line will be echomsg'd separately.
fun! gopher#internal#error(msg) abort
  call s:echo(a:msg, 'ErrorMsg')
endfun

" Output an informational message to the screen. The message can be either a
" list or a string; every line will be echomsg'd separately.
fun! gopher#internal#info(msg) abort
  call s:echo(a:msg, 'Debug')
endfun

" Trim leading and trailing whitespace from a string.
fun! gopher#internal#trim(s) abort
  return substitute(a:s, '^[ \t\r\n]*\(.\{-}\)[ \t\r\n]*$', '\1', '')
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

" List all Go buffers.
fun! gopher#internal#buffers()
  return filter(range(1, bufnr('$')), { i, v -> bufexists(l:v) && buflisted(l:v) && bufname(l:v)[-3:] is# '.go' })
endfun

" Run a command on every buffer and restore the position to the active buffer.
fun! gopher#internal#bufdo(cmd)
  let l:s = bufnr('%')
  let l:lz = &lazyredraw

  try
    set lazyredraw  " Reduces a lot of flashing
    for l:b in gopher#internal#buffers()
      silent exe l:b . 'bufdo ' . a:cmd
    endfor
  finally
    silent exe 'buffer ' . l:s
    let &lazyredraw = l:lz
  endtry
endfun

" Save all unwritten Go buffers.
fun! gopher#internal#write_all()
  let l:s = bufnr('%')
  let l:lz = &lazyredraw

  try
    set lazyredraw  " Reduces a lot of flashing
    for l:b in gopher#internal#buffers()
      exe 'buffer ' . l:b
      if &modified
        silent w
      endif
    endfor
  finally
    silent exe 'buffer ' . l:s
    let &lazyredraw = l:lz
  endtry
endfun

" Get diagnostic information about gopher.vim
fun! gopher#internal#diag(to_clipboard)
  let l:state = []

  " Disable 'commands' debug flag, as this will add a bunch of commands to history,
  " which is not very useful.
  let l:add_debug = 0
  let l:i = index(get(g:, 'gopher_debug', []), 'commands')
  if l:i > -1
    call remove(g:gopher_debug, l:i)
    let l:add_debug = 1
  endif

  try
    " Vim version.
    let l:state = add(l:state, 'VERSION')
    let l:state += s:indent(split(execute('version'), "\n")[:1])

    " Go version.
    let [l:out, l:err] = gopher#system#run(['go', 'version'])
    if l:err
      let l:state = add(l:state, '    ERROR go version exit ' . l:err)
    endif
    let l:state += s:indent(l:out)

    " GOPATH and GOROOT.
    let [l:out, l:err] = gopher#system#run(['go', 'env', 'GOPATH', 'GOROOT'])
    if l:err
      let l:state = add(l:state, '    ERROR go env exit ' . l:err)
      let l:state += s:indent(l:out)
    else
      let l:out = substitute('GOPATH=' . l:out, "\n", "\nGOROOT=", '')
      let l:state += s:indent(l:out)
    endif

    " gopher.vim version.
    let [l:out, l:err] = gopher#system#run(['git', '-C', s:root,
          \ 'log', '--format=gopher.vim version %h %ci (%cr) %s', '-n1'])
    if l:err
      let l:state = add(l:state, '    ERROR git log')
    endif
    let l:state += s:indent(l:out)
    let l:state = add(l:state, ' ')

    " List all config variables.
    let l:state = add(l:state, 'VARIABLES')
    let l:state += s:indent(filter(split(execute('let'), "\n"), { i, v -> l:v =~# '^gopher_' }))
    let l:state = add(l:state, ' ')

    " List command history (if any).
    let l:state = add(l:state, 'COMMAND HISTORY')
    for l:h in gopher#system#history()
      if l:h[4]
        let l:state = add(l:state, '    shell: ' . l:h[2])
      else
        let l:state = add(l:state, '    job: ' . l:h[2])
      endif
      let l:state = add(l:state, printf('    exit %s; took %ss', l:h[0], l:h[1]))
      let l:state += s:indent(l:h[3])
      let l:state = add(l:state, ' ')
    endfor
  finally
    if l:add_debug
      let g:gopher_debug = add(g:gopher_debug, 'commands')
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

fun! s:indent(out)
  let l:out = a:out
  if type(l:out) is v:t_string
    let l:out = split(l:out, "\n")
  endif

  return map(l:out, { i, v -> '    ' . l:v })
endfun

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
