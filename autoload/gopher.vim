" gopher.vim: Various common functions, or functions that don't have a place elsewhere.

" Output an error message to the screen. The message can be either a list or a
" string; every line will be echomsg'd separately.
fun! gopher#error(msg, ...) abort
  call s:echo(a:msg, 'ErrorMsg', a:000)
endfun

" Output an informational message to the screen. The message can be either a
" list or a string; every line will be echomsg'd separately.
fun! gopher#info(msg, ...) abort
  call s:echo(a:msg, 'Debug', a:000)
endfun

" Report if the user enabled the given debug flag.
fun! gopher#has_debug(flag) abort
  return index(g:gopher_debug, a:flag) >= 0
endfun

let s:overriden = 0

" Override vim-go.
fun! gopher#override_vimgo() abort
  if s:overriden
    return
  end

  let g:go_loaded_install = 1
  unlet b:did_ftplugin
  unlet b:current_syntax

  let &rtp = substitute(&rtp, ',[/\\a-zA-Z0-9_.\-]*[/\\]vim-go', '', '')

  au! vim-go
  au! vim-go-buffer
  au! vim-go-hi

  let l:comm = map(split(execute('comm Go'), "\n"), { i, v ->
        \ split(gopher#str#trim_space(substitute(l:v, '^\!', ' ', '')), ' ')[0]
        \ })[1:]
  for l:c in l:comm
    exe 'delcommand ' . l:c
  endfor

  let s:overriden = 1
  edit
endfun

" Echo a message to the screen and highlight it with the group in a:hi.
"
" The message can be a list or string; every line with be :echomsg'd separately.
fun! s:echo(msg, hi, ...) abort
  if type(a:msg) is v:t_list
    let l:msg = a:msg
  else
    let l:msg = a:msg
    if len(a:000) > 0 && len(a:000[0]) > 0
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
