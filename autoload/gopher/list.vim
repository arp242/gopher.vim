" list.vim: Utilities for working with lists.

" Flatten a list.
fun! gopher#list#flatten(l) abort
  let l:new = []
  for l:v in a:l
    if type(l:v) is v:t_list
      call extend(l:new, gopher#list#flatten(l:v))
    else
      call add(l:new, l:v)
    endif
  endfor
  return l:new
endfun
