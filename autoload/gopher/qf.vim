" qf.vim: Utilities for working with the quickfix and location list.

" Populate the quickfix list with the errors from out, parsed according to the
" errorformat in efm.
"
" If efm is an empty string "%f:%l:%c %m" will be used.
fun! gopher#qf#populate(out, efm, title) abort
  let l:efm = a:efm
  if l:efm is# ''
    let &l:efm = '%f:%l:%c %m'
  endif

  try
    let l:save_efm = &l:errorformat
    let &l:errorformat = l:efm

    cgetexpr a:out
    call setqflist([], 'a', {'title': a:title})
  finally
    let &l:errorformat = l:save_efm
  endtry
endfun
