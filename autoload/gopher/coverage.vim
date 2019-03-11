" Highlights.
fun! s:hi() abort
  hi def      goCoverageCovered    guibg=#dfffdf
  hi def      goCoverageUncover    guibg=#ffdfdf
endfun
augroup gopher-coverage-hi
  autocmd!
  autocmd ColorScheme * call s:hi()
augroup end
call s:hi()

" Apply coverage highlights.
fun! gopher#coverage#do() abort
  let l:tmp = tempname()
  try
    let [l:out, l:err] = gopher#system#run(['go', 'test',
          \ '-coverprofile', l:tmp,
          \ './' . expand('%:.:h')])
    if l:err
      call gopher#internal#error(l:out)
      return
    endif

    let l:profile = readfile(l:tmp)
  finally
    call delete(l:tmp)
  endtry

  call s:overlay(l:profile)
endfun

fun! gopher#coverage#clear() abort
  " TODO: don't clear all matches.
  call clearmatches()
endfun

" Read the coverprofile file and annotate the current buffer.
fun! s:overlay(profile) abort
  let l:path = gopher#internal#packagepath()

  let l:other_files = {}
  for l:line in a:profile[1:]
    let l:cov = s:parse_line(l:line)

    " Highlight other buffers later, to prevent switching back and forth and
    " adding a lot of flicker.
    " TODO: fix this.
    if l:path != l:cov.file
      "if !get(l:other_files, l:path)
      "  let l:other_files[cov.file] = []
      "endif
      "let l:other_files[cov.file] += [l:cov]
      continue
    endif

    call s:match(l:cov)
  endfor

  let l:s = bufnr('%')
  let l:lz = &lazyredraw

  "try
  "  set lazyredraw  " Reduces a lot of flashing

  "  for l:b in gopher#internal#buffers()
  "    silent exe l:b . 'buf'
  "    for l:cov in get(l:other_files, gopher#internal#packagepath(), [])
  "      call s:match(l:cov)
  "    endfor
  "  endfor
  "finally
  "  silent exe 'buffer ' . l:s
  "  let &lazyredraw = l:lz
  "endtry
endfunction

" Generate matches to be added to matchaddpos for the given coverage profile
" block
fun! s:match(cov) abort
  let l:color = 'goCoverageCovered'
  if a:cov.cnt == 0
    let l:color = 'goCoverageUncover'
  endif

  " Highlight entire lines, instead of starting at the first non-space
  " character.
  let l:startcol = a:cov.startcol
  if getline(a:cov.startline)[:l:startcol - 2] =~# '^\s*$'
    let l:startcol = 0
  endif

  " Single line.
  if a:cov.startline is# a:cov.endline
    call matchaddpos(l:color, [[a:cov.startline,
          \ l:startcol,
          \ a:cov.endcol - a:cov.startcol]])
    return
  endif

  " First line.
  call matchaddpos(l:color, [[a:cov.startline, l:startcol,
        \ len(getline(a:cov.startline)) - l:startcol]])

  " Fill lines in between.
  let l:l = a:cov.startline
  while l:l < a:cov.endline
    let l:l += 1
    call matchaddpos(l:color, [l:l])
  endwhile

  " Last line.
  call matchaddpos(l:color, [[a:cov.endline, a:cov.endcol - 1]])
endfun

" Parses a single line in to a more readable dict.
"
" The format of a line is:
"   package/file.go:startline.col,endline.col numstmt count
"
"   github.com/teamwork/apiutil/readonlybind/readonlybind.go:51.40,54.2 1 1
function! s:parse_line(line) abort
  let l:m = matchlist(a:line, '\v([^:]+):(\d+)\.(\d+),(\d+)\.(\d+) (\d+) (\d+)')
  return {
        \ 'file':      l:m[1],
        \ 'startline': str2nr(l:m[2]),
        \ 'startcol':  str2nr(l:m[3]),
        \ 'endline':   str2nr(l:m[4]),
        \ 'endcol':    str2nr(l:m[5]),
        \ 'numstmt':   l:m[6],
        \ 'cnt':       l:m[7],
        \ }
endfun
