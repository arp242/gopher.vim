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

" The .mod filetype is already used by lprolog and modsim; to make matters
" worse, lprolog already uses the keywork 'module'; from filetype.vim:
"
"   if getline(1) =~ '\<module\>'
"     setf lprolog
"   else
"     setf modsim3
"   endif
"
" So detect if this is a go.mod file based on the presence of the 'go 1.13'
" keyword so it won't break anything for people who happen to have a lprolog or
" modsim3 file named 'go.mod'.
fun! s:gomod()
  for l:i in range(1, line('$'))
    if getline(l:i) =~# '^go 1\.\d\+'
      unlet b:did_ftplugin
      set ft=gomod
      setl fileencoding=utf-8 fileformat=unix
      break
    endif
  endfor
endfun
