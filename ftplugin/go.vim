if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setlocal formatoptions-=t

setlocal comments=s1:/*,mb:*,ex:*/,://
setlocal commentstring=//\ %s
setlocal foldmethod=syntax
setlocal noexpandtab
compiler go

let b:undo_ftplugin = 'setl fo< com< cms<'

" Motions
onoremap <buffer> <silent> af :<C-u>call gopher#motion#function('a')<CR>
xnoremap <buffer> <silent> af :<C-u>call gopher#motion#function('a')<CR>
onoremap <buffer> <silent> if :<C-u>call gopher#motion#function('i')<CR>
xnoremap <buffer> <silent> if :<C-u>call gopher#motion#function('i')<CR>

onoremap <buffer> <silent> ac :<C-u>call gopher#motion#comment('a')<CR>
xnoremap <buffer> <silent> ac :<C-u>call gopher#motion#comment('a')<CR>
onoremap <buffer> <silent> ic :<C-u>call gopher#motion#comment('i')<CR>
xnoremap <buffer> <silent> ic :<C-u>call gopher#motion#comment('i')<CR>

nnoremap <buffer> <silent> ]] :<C-u>call gopher#motion#jump('n', 'next')<CR>
onoremap <buffer> <silent> ]] :<C-u>call gopher#motion#jump('o', 'next')<CR>
xnoremap <buffer> <silent> ]] :<C-u>call gopher#motion#jump('v', 'next')<CR>
nnoremap <buffer> <silent> [[ :<C-u>call gopher#motion#jump('n', 'prev')<CR>
onoremap <buffer> <silent> [[ :<C-u>call gopher#motion#jump('o', 'prev')<CR>
xnoremap <buffer> <silent> [[ :<C-u>call gopher#motion#jump('v', 'prev')<CR>

command! -bang GoDiag   call gopher#internal#diag(<bang>0)
command!       GoSetup  call gopher#system#setup()

" Rename identifier.
command! -bang -nargs=? -complete=customlist,gopher#rename#complete GoRename call gopher#rename#do(<bang>0, <f-args>)

" Modify struct tags
" TODO: think of a better command interface for this.
" :GoTags asd
" :GoTags -rm asd
command! -nargs=* -range GoAddTags    call gopher#tags#add(<line1>, <line2>, <count>, <f-args>)
command! -nargs=* -range GoRemoveTags call gopher#tags#remove(<line1>, <line2>, <count>, <f-args>)

command! -nargs=* GoTest call s:compile('gotest', <f-args>)
command! -nargs=* GoMake call s:compile('go', <f-args>)
"command! GoDef               call completor#do('definition')
"command! GoDoc               call completor#do('doc')

fun! s:compile(n, ...) abort
  let l:c = b:current_compiler
  exe 'compiler ' . a:n
  exe 'lmake ' . join(a:000)
  redraw!
  exe 'compiler ' . l:c
endfun
