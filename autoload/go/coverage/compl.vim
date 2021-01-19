" compl.vim: Some helpers to work with commandline completion.

" Return a copy of the list with only the items starting with lead.
fun! gopher#compl#filter(lead, list) abort
  return filter(a:list, {_, v -> strpart(l:v, 0, len(a:lead)) is# a:lead})
endfun

" Get the current word that's being completed.
fun! gopher#compl#word(cmdline, cursor) abort
  return s:word(a:cmdline, a:cursor, 0)
endfun

" Get the previous word.
fun! gopher#compl#prev_word(cmdline, cursor) abort
  return s:word(a:cmdline, a:cursor, 1)
endfun

fun! s:word(cmdline, cursor, prev) abort
  let l:off = -1  " No space for first word.
  let l:prev = ''
  for l:w in split(a:cmdline, ' ')
    let l:off += len(l:w) + 1
    if l:off >= a:cursor
      break
    endif
    let l:prev = l:w
  endfor

  return a:prev ? l:prev : l:w
endfun
