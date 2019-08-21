" buf.vim: Utilities for working with buffers.

" Get all lines in the buffer as a list.
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

" Returns the byte offset for the cursor.
"
" If the first argument is non-blank it will return filename:#offset
fun! gopher#buf#cursor(...) abort
  let l:o = line2byte(line('.')) + (col('.') - 2)

  if len(a:000) > 0 && a:000[0]
    return printf('%s:#%d', expand('%:p'), l:o)
  endif

  return l:o
endfun

" Replace text from byte offset 'start' to offset 'end'.
fun! gopher#buf#replace(start, end, data) abort
  let l:data = a:data
  if type(l:data) is v:t_list
    let l:data = join(l:data, "\n")
  endif

  try
    let l:save = winsaveview()
    let l:a = @a
    let l:lastline = line('$')

    let @a = l:data
    keepjumps exe 'goto' a:start
    if a:end is 0
      normal! "aP
    else
      normal! m<
      keepjumps exe 'goto' a:end
      normal! m>gv"aP
    endif
  finally
    " Keep cursor on the same line as it was before.
    let l:save['lnum']    += line('$') - l:lastline
    let l:save['topline'] += line('$') - l:lastline

    call winrestview(l:save)
    let @a = l:a

    " TODO: restore visual selection as well, but I don't think that's possible.
  endtry
endfun
