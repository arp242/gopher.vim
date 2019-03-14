" diag.vim: implement :GoDiag

let s:root = expand('<sfile>:p:h:h:h') " Root dir of this plugin.

" Get diagnostic information about gopher.vim
fun! gopher#diag#do(to_clipboard) abort
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
