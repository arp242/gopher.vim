let s:root = expand('<sfile>:p:h:h:h') " Root dir of this plugin.

" Output an error message to the screen. The message can be either a list or a
" string; every line will be echomsg'd separately.
fun! gopher#internal#error(msg, ...) abort
  call s:echo(a:msg, 'ErrorMsg', a:000)
endfun

" Output an informational message to the screen. The message can be either a
" list or a string; every line will be echomsg'd separately.
fun! gopher#internal#info(msg, ...) abort
  call s:echo(a:msg, 'Debug', a:000)
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
endfun

" Report if the current buffer is a Go test file.
fun! gopher#internal#is_test() abort
  return expand('%')[-8:] is# '_test.go'
endfun

" Get the package path for the file in the current buffer.
" TODO: cache results?
fun! gopher#internal#package() abort
  let [l:out, l:err] = gopher#system#run(['go', 'list', expand('%:p:h')])
  if l:err
    if gopher#str#has_suffix(l:out, 'cannot import absolute path')
      let l:out = 'cannot determine module path (outside GOPATH, no go.mod)'
    endif
    call gopher#internal#error(l:out)
    return ''
  endif

  return l:out
endfun

" Get path to file in current buffer as package/path/file.go
fun! gopher#internal#packagepath() abort
  return gopher#internal#package() . '/' . expand('%:t')
endfun

" Report if the user enabled a debug flag.
fun! gopher#internal#has_debug(flag) abort
  return index(g:gopher_debug, a:flag) >= 0
endfun

" Report if the current buffer is inside GOPATH.
fun! gopher#internal#in_gopath() abort
  let [l:out, l:err] = gopher#system#run(['go', 'env', 'GOPATH'])
  if l:err
    return gopher#internal#error(l:out)
  endif

  let l:path = expand('%:p')
  for l:gopath in split(l:out, gopher#internal#platform('win') ? ';' : ':')
    if gopher#str#has_prefix(l:path, l:out)
      return 1
    endif
  endfor

  return 0
endfun

" Check if this is the requested OS.
"
" Supports 'win', 'unix'.
fun! gopher#internal#platform(n) abort
  if a:n is? 'win'
    return has('win16') || has('win32') || has('win64')
  elseif a:n is? 'unix'
    return has('unix')
  endif

  call gopher#internal#error('gopher#internal#platform: unknown parameter: ' . a:n)
endfun

let s:go_commands = ['go', 'bug', 'build', 'clean', 'doc', 'env', 'fix', 'fmt',
                   \ 'generate', 'get', 'install', 'list', 'mod', 'run', 'test',
                   \ 'tool', 'version', 'vet']

" Add g:gopher_build_tags to the flag_list; will be merged with existing tags
" (if any).
fun! gopher#internal#add_build_tags(flag_list) abort
  if get(g:, 'gopher_build_tags', []) == []
    return a:flag_list
  endif

  let l:last_flag = 0
  for l:i in range(len(a:flag_list))
    if a:flag_list[l:i][0] is# '-' || index(s:go_commands, a:flag_list[l:i]) > -1
      let l:last_flag = l:i
    endif

    if a:flag_list[l:i] is# '-tags'
      let l:tags = uniq(split(gopher#str#trim(a:flag_list[l:i+1], "\"'"), ' ') + g:gopher_build_tags)
      return a:flag_list[:l:i]
            \ + ['"' . join(l:tags, ' ') . '"']
            \ +  a:flag_list[l:i+2:]
    endif
  endfor

  return a:flag_list[:l:last_flag]
        \ + ['-tags', '"' . join(g:gopher_build_tags, ' ') . '"']
        \ + a:flag_list[l:last_flag+1:]
endfun

" Get diagnostic information about gopher.vim
fun! gopher#internal#diag(to_clipboard) abort
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
    let l:state += s:indent(join(split(execute('version'), "\n")[:1], '; '))

    " Go version.
    let [l:version, l:err] = gopher#system#run(['go', 'version'])
    if l:err
      let l:state = add(l:state, '    ERROR go version exit ' . l:err)
      let l:version = ''
    endif

    " GOPATH and GOROOT.
    let [l:out, l:err] = gopher#system#run(['go', 'env', 'GOPATH', 'GOROOT'])
    if l:err
      let l:state += s:indent(l:version)
      let l:state = add(l:state, '    ERROR go env exit ' . l:err)
      let l:state += s:indent(l:out)
    else
      let l:out = substitute('GOPATH=' . l:out, "\n", '; GOROOT=', '')
      let l:state += s:indent(printf('%s; %s; GO111MODULE=%s', l:version, l:out,
            \ $GO111MODULE is# '' ? '[unset]' : $GO111MODULE))
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
    let l:state = add(l:state, 'COMMAND HISTORY (newest on top)')
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

fun! s:indent(out) abort
  let l:out = a:out
  if type(l:out) is v:t_string
    let l:out = split(l:out, "\n")
  endif

  return map(l:out, { i, v -> '    ' . l:v })
endfun

" Echo a message to the screen and highlight it with the group in a:hi.
"
" The message can be a list or string; every line with be :echomsg'd separately.
fun! s:echo(msg, hi, ...) abort
  if type(a:msg) is v:t_list
    let l:msg = a:msg
  else
    let l:msg = a:msg
    if len(a:000) > 0
      let l:msg = call('printf', [a:msg] + a:000[0])
    endif
    let l:msg = split(l:msg, "\n")
  endif

  " Tabs display as ^I or <09>, so manually expand them.
  let l:msg = map(l:msg, 'substitute(v:val, "\t", "        ", "")')

  exe 'echohl ' . a:hi
  for line in l:msg
    echom 'gopher.vim: ' . line
  endfor
  echohl None
endfun
