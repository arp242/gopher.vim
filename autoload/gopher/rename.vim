" Commandline completion: original, unexported camelCase, and exported
" CamelCase.
function! gopher#rename#complete(lead, cmdline, cursor) abort
  let l:word = expand('<cword>')
  return filter(
        \ uniq(sort([l:word, s:unexport(l:word), s:export(l:word)])),
        \ { i, v -> strpart(l:v, 0, len(a:lead)) is# a:lead })
endfun

fun! gopher#rename#do(bang, ...) abort
  " No argument: toggle export.
  " TODO: convert to camelCase if it's snake_case or PascalCase if it's
  " Snake_case or ALLCAPS.
  if a:0 is 0
    let l:to = expand('<cword>') =~# '^[A-Z]'
          \ ? s:unexport(expand('<cword>'))
          \ : s:export(expand('<cword>'))
  else
    let l:to = a:1
  endif

  if &modified
    silent w
  endif

  " clear qlist.
  cexpr []

  " Make sure the buffer can't be modified since gorename will write stuff to
  " disk, and overwrite the user's changes.
  setl nomodifiable

  try
    " TODO: investigate async options.
    let [l:out, l:err] = gopher#system#tool(['gorename', '-to', l:to,
          \ '-tags', get(g:, 'gopher_build_tags', ''),
          \ '-offset', gopher#internal#cursor_offset(1)
          \ ] + get(g:, 'gopher_gorename_flags', []))
    if l:err
      call s:errors(l:out, a:bang)
      return
    endif

    " Reload buffer.
    silent edit
  finally
    set modifiable
  endtry

  call gopher#internal#info(l:out)
endfun

fun! s:errors(out, bang) abort
  " gorename: -offset "/home/martin/go/src/a/a.go:#125": cannot parse file: /home/martin/go/src/a/a.go:18:2: expected 'IDENT', found 'EOF'
  " gorename: -offset "/home/martin/go/src/a/a.go:#269": cannot parse file: /home/martin/go/src/a/a.go:17:1: expected declaration, found asde
  "
  " /home/martin/go/src/a/a.go:18:2: undeclared name: x
  " /home/martin/go/src/a/a.go:19:2: undeclared name: x
  " gorename: couldn't load packages due to errors: a
  "
  " gorename: -offset "/home/martin/go/src/a/dir1/asd.go:#38": no identifier at this position
  "
  " /home/martin/go/src/a/dir1/asd.go:5:6: renaming this func "QWEzxcasdzxc" to "x"
  " /home/martin/go/src/a/dir1/dir1.go:5:6: <09>conflicts with func in same block
  "
  " /home/martin/go/src/a/dir1/asd.go:7:2: renaming this var "v" to "asd"
  " /home/martin/go/src/a/dir1/asd.go:6:2: <09>conflicts with var in same block
  if a:out =~# '": no identifier at this position'
    call gopher#internal#error('gorename: no identifier at this position')
    return
  endif

  if a:out =~# ': renaming this.*conflicts with'
    let l:out = map(split(a:out, "\n"), { i, v -> split(l:v, ':')})

    call gopher#internal#error(
          \ gopher#internal#trim(join(l:out[0][3:]))
          \ . ' ' .
          \ gopher#internal#trim(join(l:out[1][3:])))
    return
  endif

  " TODO: allow configuring of loclist/qflist, auto/open close .. maybe re-use
  " ALE vars?
  for l:err in split(a:out, "\n")
    " Not a very useful line to add.
    if l:err =~# "^gorename: couldn't load packages due to errors:"
      continue
    endif

    let l:err = substitute(l:err, '\v^gorename: (-offset ".{-}:#\d{-}": cannot parse file: )?', '', '')
    let l:err = split(l:err, ':')
    if len(l:err) < 3
      continue
    endif

    call setloclist(winnr(), [{
          \ 'type':     'E',
          \ 'filename': l:err[0],
          \ 'lnum':     l:err[1],
          \ 'col':      l:err[2],
          \ 'text':     join(l:err[3:], ':'),
          \ }], 'a')
  endfor

  if len(getloclist(winnr())) is 0
    call gopher#internal#error(a:out)
    return
  endif

  exe 'copen ' . len(getloclist(winnr()))
  if !a:bang
    cc 1
  endif
endfun

" Copied from tpope/vim-abolish.
fun! s:unexport(word) abort
  let l:word = substitute(a:word, '-', '_', 'g')
  if l:word !~# '_' && l:word =~# '\l'
    return substitute(l:word, '^.', '\l&', '')
  else
    return substitute(l:word, '\C\(_\)\=\(.\)', '\=submatch(1)==""?tolower(submatch(2)) : toupper(submatch(2))','g')
  endif
endfun

fun! s:export(word) abort
  let l:word = s:unexport(a:word)
  return toupper(l:word[0]) . l:word[1:]
endfun
