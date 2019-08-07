if exists(':GoDef') >= 2
  if get(g:, 'gopher_override_vimgo', 0)
    call gopher#override_vimgo()
  else
    echohl Error
    echom 'It looks like vim-go is installed; running both vim-go and gopher.vim will not'
    echom 'work well, so GOPHER.VIM WILL NOT LOAD.'
    echom 'Add this to your vimrc to override vim-go:'
    echom '   let g:gopher_override_vimgo = 1'
    echom 'This is only recommended for testing/experimenting.'
    echohl None
    sleep 2
    finish
  endif
endif

if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

call gopher#init#config()
call gopher#init#version()

setlocal formatoptions-=t
setlocal comments=s1:/*,mb:*,ex:*/,://
setlocal commentstring=//\ %s
setlocal foldmethod=syntax
setlocal noexpandtab

" Special-fu to ensure we don't clobber the buffer with errors.
" TODO: /dev/stdin is not completely portable, but I don't know how to get the
" same effect with standard POSIX redirection.
let &l:equalprg = 'gofmt 2>/dev/null || cat /dev/stdin'

compiler go

let b:undo_ftplugin = 'setl formatoptions< comments< commentstring< equalprg<'

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

" Mappings
nnoremap <buffer> <Plug>(gopher-popup)  :call gopher#frob#popup()<CR>
nnoremap <buffer> <Plug>(gopher-if)     :call gopher#frob#if()<CR>
nnoremap <buffer> <Plug>(gopher-return) :call gopher#frob#ret(0)<CR>
nnoremap <buffer> <Plug>(gopher-error)  :call gopher#frob#ret(1)<CR>
nnoremap <buffer> <Plug>(gopher-impl)   :call gopher#frob#impl()<CR>

inoremap <buffer> <Plug>(gopher-popup)  <C-o>:call gopher#frob#popup()<CR>
inoremap <buffer> <Plug>(gopher-if)     <C-o>:call gopher#frob#if()<CR>
inoremap <buffer> <Plug>(gopher-return) <C-o>:call gopher#frob#ret(0)<CR>
inoremap <buffer> <Plug>(gopher-error)  <C-o>:call gopher#frob#ret(1)<CR>
inoremap <buffer> <Plug>(gopher-impl)   <C-o>:call gopher#frob#impl()<CR>

fun! s:map(key, map) abort
  let l:key = get(g:gopher_map, a:key, '')
  if type(a:key) is v:t_string
    let l:key = [l:key, l:key]
  endif

  if l:key[0] isnot# ''
    exe printf('nmap %s%s %s', g:gopher_map['_nmap_prefix'], l:key[0], a:map)
  endif

  if l:key[1] isnot# ''
    exe printf('imap %s%s %s', g:gopher_map['_imap_prefix'], l:key[1], a:map)
    if g:gopher_map['_imap_ctrl']
      exe printf('imap %s<C-%s> %s', g:gopher_map['_imap_prefix'], l:key[1], a:map)
    endif
  endif
endfun

" TODO: errors don't show well from insert mode, e.g. <C-k>i where there's no if
" (works fine with ;i).
if g:gopher_map isnot 0
  " Map the popup; the rest of the mappings are handled inside there, so we
  " don't need to map them here.
  if g:gopher_map['_popup']
    exe printf('nmap %s <Plug>(gopher-popup)', g:gopher_map['_nmap_prefix'])
    exe printf('imap %s <Plug>(gopher-popup)', g:gopher_map['_imap_prefix'])
  else
    call s:map('if',     '<Plug>(gopher-if)')
    call s:map('return', '<Plug>(gopher-return)')
    call s:map('error',  '<Plug>(gopher-error)')
    call s:map('impl',   '<Plug>(gopher-impl)')
  endif
endif

" Commands
command! -bang                                                  GoDiag     call gopher#diag#do(<bang>0)
command!                                                        GoSetup    call gopher#system#setup()

command! -nargs=* -complete=customlist,gopher#coverage#complete GoCoverage call gopher#coverage#do(<f-args>)
command! -nargs=* -complete=customlist,gopher#frob#complete     GoFrob     call gopher#frob#cmd(<f-args>)
command! -nargs=+ -complete=customlist,gopher#guru#complete     GoGuru     call gopher#guru#do(<f-args>)
command! -nargs=+                                               GoImport   call gopher#import#do(<f-args>)
command! -nargs=? -complete=customlist,gopher#rename#complete   GoRename   call gopher#rename#do(<f-args>)
command! -nargs=* -range                                        GoTags     call gopher#tags#modify(<line1>, <line2>, <count>, <f-args>)
