" coverage.vim: Implement :GoCoverage.

let s:visible = 0

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
augroup gopher-coverage
  au!
  au ColorScheme *    call s:hi()
  au BufWinLeave *.go call gopher#coverage#clear()
augroup end
call s:hi()

" Complete the special flags and some common flags people might want to use.
fun! gopher#coverage#complete(lead, cmdline, cursor) abort
  " TODO: -run can be completed with a list of tests.
  return gopher#compl#filter(a:lead, ['clear', 'toggle', '-run', '-race', '-tags'])
endfun

" Apply or clear coverage highlights.
fun! gopher#coverage#do(...) abort
  if a:0 is 1 && (a:1 is# 'clear' || (a:1 is# 'toggle' && s:visible))
    return gopher#coverage#clear()
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

" Clear any existing highlights.
fun! gopher#coverage#clear() abort
  let s:visible = 0
  for l:m in getmatches()
    if l:m.group is# 'goCoverageCovered' || l:m.group is# 'goCoverageUncover'
      call matchdelete(l:m.id)
    endif
  endfor
endfun

" Read the coverprofile file and annotate all loaded buffers.
"
" TODO: no feedback if there are no test with -run:
"
"    shell: 'go' 'test' '-coverprofile' '/tmp/v8o0H7U/2' '-run' 'TestX' './.'
"    exit 0; took 0.900s
"    ok  <09>zgo.at/goatcounter<09>0.007s<09>coverage: 0.5% of statements [no tests to run]
"
" Maybe add some feedback in general if a buffer has 0 coveraged lines?
fun! s:apply(profile) abort
  let l:path = gopher#go#packagepath()
  if l:path is# ''
    return
  endif

  let s:visible = 1

  let l:other_files = {}
  for l:line in a:profile[1:]
    let l:cov = s:parse_line(l:line)

    if l:path is# l:cov.file
      call gopher#coverage#_highlight_(l:cov)
      continue
    endif

    " Highlight other buffers later to prevent switching back and forth.
    if get(l:other_files, l:cov.file) is 0
      let l:other_files[l:cov.file] = []
    endif
    call add(l:other_files[l:cov.file], l:cov)
  endfor

  " Highlight all the other buffers.
  " TODO: also hook in to e.g. BufWinEnter to highlight new buffers automatically.
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

      "silent exe l:b . 'buf'
      silent exe l:b . 'sbuf'
      for l:cov in get(l:other_files, gopher#go#packagepath(), [])
        call gopher#coverage#_highlight_(l:cov)
      endfor
    endfor
  finally
    silent exe 'sbuf ' . l:s
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
