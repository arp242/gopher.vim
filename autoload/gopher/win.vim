" win.vim: Utilities for working with windows.

" Get a list of all Go window IDs for all tabs.
fun! gopher#win#list() abort
  let l:r = []
  for l:tab in range(1, tabpagenr('$'))
    let l:r += range(1, tabpagewinnr(l:tab, '$'))
          \ ->map({ _, v -> [win_getid(v, l:tab), winbufnr(win_getid(v, l:tab))] })
          \ ->filter({ _, v -> buflisted(v[1]) && bufname(v[1])[-3:] is# '.go' })
          \ ->map({ _, v -> v[0] })
  endfor
  return l:r
endfun
