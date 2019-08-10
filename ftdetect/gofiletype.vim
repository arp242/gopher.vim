" vint: -ProhibitAutocmdWithNoGroup

au BufRead,BufNewFile *.gohtml set filetype=gohtml.html
au BufRead,BufNewFile *.gotxt  set filetype=gotxt
au BufRead,BufNewFile *.slide  set filetype=gopresent
au BufRead,BufNewFile go.mod   call s:gomod()

" These settings are global, but we want to override them when reading Go files,
" as they're always UTF-8.
let s:ffs   = ''
let s:fencs = ''
au BufNewFile *.go setf go | setl fileencoding=utf-8 fileformat=unix
au BufRead *.go
      \  let s:ffs   = &fileformats
      \| let s:fencs = &fileencodings
      \| set fileformats=unix fileencodings=utf-8 | setf go
au BufReadPost *.go let &fileformats = s:ffs | let &fileencodings = s:fencs

" Set the filetype if the first non-comment and non-blank line starts with
" 'module <path>'.
fun! s:gomod()
  for l:i in range(1, line('$'))
    let l:l = getline(l:i)
    if l:l ==# '' || l:l[:1] ==# '//'
      continue
    endif
    if l:l =~# '^module .\+'
      set filetype=gomod
    endif
    break
  endfor
endfun
