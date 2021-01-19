" compl.vim: Some helpers to work with commandline completion.

" Return a copy of the list with only the items starting with lead.
fun! go#coverage#compl#filter(lead, list) abort
  return filter(a:list, {_, v -> strpart(l:v, 0, len(a:lead)) is# a:lead})
endfun
