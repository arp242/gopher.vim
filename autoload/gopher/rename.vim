" rename.vim: Implement :GoRename.

" Commandline completion: original, unexported camelCase, and exported
" CamelCase.
fun! gopher#rename#complete(lead, cmdline, cursor) abort
  let l:word = expand('<cword>')
  return gopher#compl#filter(a:lead, uniq(sort([l:word, s:unexport(l:word), s:export(l:word)])))
endfun

" Rename the identifier under the cursor to the identifier in the first
" argument.
fun! gopher#rename#do(...) abort
  if !gopher#go#in_gopath()
    return gopher#error(
      \ 'gorename does not work with modules yet. https://github.com/golang/go/issues/27571')
  endif

  " No argument; try to make a sane decision:
  " - ALLCAPS -> Allcaps
  " - snake_case -> snakeCase     (Convert snake_case while keeping export status)
  " - Snake_case -> SnakeCase
  " - Otherwise toggle export status.
  if a:0 is 0
    let l:to = gopher#rename#_auto_to_(expand('<cword>'))
  else
    let l:to = a:1
  endif

  call gopher#buf#write_all()
  "call setqflist([])

  " Make sure the buffer can't be modified since gorename will write stuff to
  " disk, and overwrite the user's changes.
  " Set this for *all* buffers since gorename can modify multiple files.
  call gopher#buf#doall('set nomodifiable')
  let l:autoread = &autoread
  set autoread

  try
    call gopher#system#tool_job({e, o -> s:done(l:e, l:o, l:autoread)}, [
          \ 'gorename',
          \ '-to',     l:to,
          \ '-offset', gopher#buf#cursor(1)
          \ ] + gopher#go#add_build_tags(get(g:, 'gopher_gorename_flags', [])))
  catch
    " Just so we don't leave the buffer in nomod state on errors, and it doesn't
    " hurt to do twice.
    call gopher#buf#doall('set modifiable')
    let &autoread = l:autoread
  endtry
endfun

fun! s:done(exit, out, autoread) abort
  checktime
  let &autoread = a:autoread
  call gopher#buf#doall('set modifiable')

  if a:exit > 0
    return gopher#rename#_errors_(a:out)
  endif
  call gopher#info(a:out)
endfun

" Display an error.
fun! gopher#rename#_errors_(out) abort
  if a:out =~# '": no identifier at this position'
    return gopher#error('gorename: no identifier at this position')
  endif

  if a:out =~# ': renaming this.*\(would conflict\|conflicts with\)'
    " Remove all instances of the file path in case of multi-line messages, which
    " look like:
    "   /home/martin/go/src/a/a.go:7:6: renaming this func "v" to "b"
    "   /home/martin/go/src/a/a.go:8:6:         conflicts with func in same block
    let l:path = matchstr(a:out, '^.\{-}:')
    let l:pat = gopher#str#escape(l:path) . '\d\+:\d\+: '
    let l:out = a:out[:len(l:path)-1] . substitute(a:out[len(l:path):], l:pat, '', '')
    let l:out = substitute(l:out, '\s\+', ' ', 'g')

    return gopher#error(printf('gorename: %s', l:out))
  endif

  " Probably compile errors.
  for l:err in split(a:out, "\n")
    " Not a very useful line to add.
    if l:err =~# "^gorename: couldn't load packages due to errors:"
      continue
    endif
    call gopher#error('gorename: %s', l:err)
  endfor
endfun

fun! gopher#rename#_auto_to_(w) abort
  if a:w =~# '^\u\+$'
    return a:w[0] . tolower(a:w[1:])
  elseif a:w =~# '_'
    return a:w =~# '^\u' ? s:export(a:w) : s:unexport(a:w)
  else
    return a:w =~# '^\u' ? s:unexport(a:w) : s:export(a:w)
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
