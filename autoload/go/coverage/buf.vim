" buf.vim: Utilities for working with buffers.

" Get a list of all Go bufnrs.
function! go#coverage#buf#list() abort
  return filter(
        \ range(1, bufnr('$')),
        \ { i, v -> bufexists(l:v) && buflisted(l:v) && bufname(l:v)[-3:] is# '.go' })
endfunction

" Run a command on every Go buffer and restore the position to the active
" buffer.
function! go#coverage#buf#doall(cmd) abort
  let l:s = bufnr('%')
  let l:lz = &lazyredraw

  try
    set lazyredraw  " Reduces a lot of flashing
    for l:b in go#coverage#buf#list()
      silent exe l:b . 'bufdo ' . a:cmd
    endfor
  finally
    silent exe 'buffer ' . l:s
    let &lazyredraw = l:lz
  endtry
endfunction
