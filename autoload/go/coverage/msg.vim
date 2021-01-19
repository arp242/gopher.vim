" msg.vim: Various common functions, or functions that don't have a place elsewhere.

" Output an error message to the screen. The message can be either a list or a
" string; every line will be echomsg'd separately.
fun! go#coverage#msg#error(msg, ...) abort
  call s:echo(a:msg, 'ErrorMsg', a:000)
endfun

" Output an informational message to the screen. The message can be either a
" list or a string; every line will be echomsg'd separately.
fun! go#coverage#msg#info(msg, ...) abort
  call s:echo(a:msg, 'Debug', a:000)
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
  let l:msg = map(l:msg, { _, v -> substitute(l:v, "\t", '      ', '') })

  " Redrawing here means there will be a better chance for messages to show.
  redraw

  exe 'echohl ' . a:hi
  for l:line in l:msg
    echom 'msg.vim: ' . l:line
  endfor
  echohl None

  " Add a delay when called from insert mode, because otherwise the user will
  " never see the message.
  " TODO: maybe there is a better way? I can't find one if there is...
  if mode() is# 'i' && a:hi is# 'ErrorMsg'
    sleep 1
  endif
endfun
