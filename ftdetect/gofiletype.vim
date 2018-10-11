" We take care to preserve the user's fileencodings and fileformats,
" because those settings are global (not buffer local), yet we want
" to override them for loading Go files, which are defined to be UTF-8.
let s:current_fileformats = ''
let s:current_fileencodings = ''

" define fileencodings to open as utf-8 encoding even if it's ascii.
function! s:gofiletype_pre() abort
  let s:current_fileformats = &g:fileformats
  let s:current_fileencodings = &g:fileencodings
  set fileencodings=utf-8 fileformats=unix
  setf go
endfunction

" restore fileencodings as others
function! s:gofiletype_post() abort
  let &g:fileformats = s:current_fileformats
  let &g:fileencodings = s:current_fileencodings
endfunction

augroup plugin-gopher
  au BufNewFile  *.go setf go | setl fileencoding=utf-8 fileformat=unix
  au BufRead     *.go call s:gofiletype_pre()
  au BufReadPost *.go call s:gofiletype_post()

  au BufRead,BufNewFile *.tmpl  set filetype=gohtmltmpl
  au BufRead,BufNewFile *.slide set filetype=gopresent

  " Set the filetype if the first non-comment and non-blank line starts with
  " 'module <path>'.
  au BufNewFile,BufRead go.mod call s:gomod()
augroup end

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
