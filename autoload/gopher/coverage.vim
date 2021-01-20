" coverage.vim: Implement :GoCoverage.

let s:visible = 0
let s:coverage = {}

" Highlights.
fun! s:hi() abort
  if &background is# 'dark'
    hi def      goCoverageCovered    guibg=#005000 ctermbg=28
    hi def      goCoverageUncover    guibg=#500000 ctermbg=52
  else
    hi def      goCoverageCovered    guibg=#dfffdf ctermbg=120
    hi def      goCoverageUncover    guibg=#ffdfdf ctermbg=223
  endif
endfun
call s:hi()

fun! s:au() abort
  augroup gopher.vim-coverage
    au!
    au ColorScheme *    call s:hi()
    au BufWinLeave *.go call gopher#coverage#clear_hi()
    au BufWinEnter *.go
          \  for s:cov in get(s:coverage, gopher#go#packagepath(), [])
          \|   call gopher#coverage#_highlight_(s:cov)
          \| endfor
  augroup end
endfun

" Complete the special flags and some common flags people might want to use.
fun! gopher#coverage#complete(lead, cmdline, cursor) abort
  return gopher#compl#filter(a:lead, ['clear', 'toggle', '-run', '-race', '-tags'])
endfun

" Apply or clear coverage highlights.
fun! gopher#coverage#do(...) abort
  if a:0 is 1 && (a:1 is# 'clear' || (a:1 is# 'toggle' && s:visible))
    return gopher#coverage#stop()
  endif

  let l:args = a:000
  if a:0 is 1 && (a:1 is# 'toggle')
    let l:args = []
  endif

  let l:tmp = tempname()
  try
    let [l:out, l:err] = gopher#system#run(['go', 'test',
          \ '-coverprofile', l:tmp] +
          \ gopher#go#add_build_tags(l:args) +
          \ ['./' . expand('%:.:h')])
    if l:err
      return gopher#error(l:out)
    endif

    if l:out =~# '\[no tests to run\]'
      return gopher#error('no tests to run')
    endif

    let l:profile = readfile(l:tmp)
  finally
    call delete(l:tmp)
  endtry

  call s:apply(l:profile)
endfun

" Report if the coverage display is currently visible.
fun! gopher#coverage#is_visible() abort
  return s:visible
endfun

" Clear any existing highlights for the current buffer.
fun! gopher#coverage#clear_hi() abort
  for l:m in getmatches()
    if l:m.group is# 'goCoverageCovered' || l:m.group is# 'goCoverageUncover'
      call matchdelete(l:m.id)
    endif
  endfor
endfun

" Stop coverage mode.
fun! gopher#coverage#stop() abort
  let s:visible = 0
  let s:coverage = {}
  silent! au! gopher-coverage

  call gopher#coverage#clear_hi()

  " TODO: Not sure why gopher#buf#doall() doesn't work here?
  let l:s = bufnr('%')
  let l:lz = &lazyredraw
  let l:swb = &switchbuf
  try
    set lazyredraw
    set switchbuf=useopen,usetab,newtab

    for l:b in gopher#buf#list()
      if l:b is l:s || !bufloaded(l:b)
        continue
      endif

      silent exe l:b . 'buf'
      call gopher#coverage#clear_hi()
    endfor
  finally
    silent exe 'buf ' . l:s
    let &lazyredraw = l:lz
    let &switchbuf = l:swb
  endtry
endfun

" Read the coverprofile file and annotate all loaded buffers.
fun! s:apply(profile) abort
  let l:path = gopher#go#packagepath()
  if l:path is# ''
    return
  endif

  call s:au()
  let s:visible = 1
  let s:coverage = {}  " Script-local so it can be accessed from autocmd.

  for l:line in a:profile[1:]
    let l:cov = s:parse_line(l:line)

    if l:path is# l:cov.file
      call gopher#coverage#_highlight_(l:cov)
      "continue
    endif

    " Highlight other buffers later to prevent switching back and forth.
    if get(s:coverage, l:cov.file) is 0
      let s:coverage[l:cov.file] = []
    endif
    call add(s:coverage[l:cov.file], l:cov)
  endfor

  " Highlight all the other buffers.
  let l:s = bufnr('%')
  let l:lz = &lazyredraw
  let l:swb = &switchbuf
  try
    set lazyredraw
    set switchbuf=useopen,usetab,newtab
    for l:b in gopher#buf#list()
      if l:b is l:s || !bufloaded(l:b)
        continue
      endif

      silent exe l:b . 'buf'
      for l:cov in get(s:coverage, gopher#go#packagepath(), [])
        call gopher#coverage#_highlight_(l:cov)
      endfor
    endfor
  finally
    silent exe 'buf ' . l:s
    let &lazyredraw = l:lz
    let &switchbuf = l:swb
  endtry
endfun

" Highlight the buffer described in cov.
fun! gopher#coverage#_highlight_(cov) abort
  let l:color = 'goCoverageCovered'
  if a:cov.cnt is 0
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
" For example:
"   github.com/teamwork/apiutil/readonlybind/readonlybind.go:51.40,54.2 1 1
fun! s:parse_line(line) abort
  let l:m = matchlist(a:line, '\v([^:]+):(\d+)\.(\d+),(\d+)\.(\d+) (\d+) (\d+)')
  return {
        \ 'file':      l:m[1],
        \ 'startline': str2nr(l:m[2]),
        \ 'startcol':  str2nr(l:m[3]),
        \ 'endline':   str2nr(l:m[4]),
        \ 'endcol':    str2nr(l:m[5]),
        \ 'numstmt':   str2nr(l:m[6]),
        \ 'cnt':       str2nr(l:m[7]),
        \ }
endfun
