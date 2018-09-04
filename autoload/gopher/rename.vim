" Commandline completion: original, unexported camelCase, and exported
" CamelCase.
function! gopher#rename#complete(lead, cmdline, cursor)
  let l:word = expand('<cword>')
  return filter(
        \ uniq(sort([l:word, s:unexport(l:word), s:export(l:word)])),
        \ { i, v -> strpart(l:v, 0, len(a:lead)) is# a:lead })
endfun

fun! gopher#rename#do(bang, ...) abort
  " No argument: toggle export.
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

  lexpr []

  " TODO: build tags.
  " TODO: gopher_debug flag for -v
  let [l:out, l:err] = gopher#internal#tool(['gorename', '-to', l:to,
        \ '-offset', gopher#internal#cursor_offset(1)])

  " No error
  if !l:err
    " Reload buffer.
    silent edit

    call gopher#internal#info(l:out)
    return
  endif

  " gorename: -offset "/home/martin/go/src/a/a.go:#125": cannot parse file: /home/martin/go/src/a/a.go:18:2: expected 'IDENT', found 'EOF'
  " gorename: -offset "/home/martin/go/src/a/a.go:#269": cannot parse file: /home/martin/go/src/a/a.go:17:1: expected declaration, found asde
  "
  " /home/martin/go/src/a/a.go:18:2: undeclared name: x
  " /home/martin/go/src/a/a.go:19:2: undeclared name: x
  " gorename: couldn't load packages due to errors: a

  let l:errs = filter(split(l:out, "\n"), { i, v -> l:v !~# "^gorename: couldn't load packages due to errors:" })
  let l:errs = map(l:errs, { i, v -> substitute(l:v, '\v^gorename: (-offset ".{-}:#\d{-}": cannot parse file: )?', '', '') })

  " TODO: allow configuring of loclist/qflist, auto/open close .. maybe re-use
  " ALE vars?
  for l:err in l:errs
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
    call gopher#internal#error(l:out)
    return
  endif

  exe 'lopen ' . len(getloclist(winnr()))
  if !a:bang
    ll 1
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
