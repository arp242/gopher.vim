" dict.vim: Utilities for working with dictionaries.

" Merge two dictionaries, also recursively merging nested keys.
"
" Use extend() if you don't need to merge nested keys.
fun! gopher#dict#merge(defaults, override) abort
  let l:new = copy(a:defaults)
  for [l:k, l:v] in items(a:override)
    let l:new[l:k] = (type(l:v) is v:t_dict && type(get(l:new, l:k)) is v:t_dict)
          \ ? gopher#dict#merge(l:new[l:k], l:v)
          \ : l:v
  endfor
  return l:new
endfun
