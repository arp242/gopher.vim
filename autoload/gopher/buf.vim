" Buffer utilities.

" Get all lines in the buffer as a a list.
fun! gopher#buf#lines() abort
  return getline(1, '$')
endfun

" Get a list of all Go bufnrs.
fun! gopher#buf#list() abort
  return filter(
        \ range(1, bufnr('$')),
        \ { i, v -> bufexists(l:v) && buflisted(l:v) && bufname(l:v)[-3:] is# '.go' })
endfun

" Run a command on every Go buffer and restore the position to the active
" buffer.
fun! gopher#buf#doall(cmd) abort
  let l:s = bufnr('%')
  let l:lz = &lazyredraw

  try
    set lazyredraw  " Reduces a lot of flashing
    for l:b in gopher#buf#list()
      silent exe l:b . 'bufdo ' . a:cmd
    endfor
  finally
    silent exe 'buffer ' . l:s
    let &lazyredraw = l:lz
  endtry
endfun

" Save all unwritten Go buffers.
fun! gopher#buf#write_all() abort
  let l:s = bufnr('%')
  let l:lz = &lazyredraw

  try
    set lazyredraw  " Reduces a lot of flashing
    for l:b in gopher#buf#list()
      exe 'buffer ' . l:b
      if &modified
        silent w
      endif
    endfor
  finally
    silent exe 'buffer ' . l:s
    let &lazyredraw = l:lz
  endtry
endfun

