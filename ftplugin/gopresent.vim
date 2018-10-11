if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

nnoremap <buffer> <silent> ]] :<C-u>call gopher#present#jump('n', 'next')<CR>
onoremap <buffer> <silent> ]] :<C-u>call gopher#present#jump('o', 'next')<CR>
xnoremap <buffer> <silent> ]] :<C-u>call gopher#present#jump('v', 'next')<CR>
nnoremap <buffer> <silent> [[ :<C-u>call gopher#present#jump('n', 'prev')<CR>
onoremap <buffer> <silent> [[ :<C-u>call gopher#present#jump('o', 'prev')<CR>
xnoremap <buffer> <silent> [[ :<C-u>call gopher#present#jump('v', 'prev')<CR>
