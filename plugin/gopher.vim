if exists('g:loaded_gopher')
  finish
endif
let g:loaded_gopher = 1

let s:warn = 0

" Make sure it's using a new-ish version of Vim.
if has('nvim')
  " TODO: check nvim version, too.
  " TODO: this Vim version was plucked out of the air. Make a more informed
  " decision.
elseif v:version < 800 || (v:version == 800 && !has('patch1000'))
  echohl Error
  echom "gopher.vim requires Vim 8.0.500 or newer"
  echohl None
  let s:warn = 1
endif

" Ensure people have Go installed correctly.
let s:v = system('go version')
if v:shell_error > 0 || s:v !~# '^go version go1\.\d\d .\+/.\+$'
  echohl Error
  echom "Go doesn't seem installed correctly? 'go version' failed with:"
  for s:l in split(s:v, "\n")
    echom s:l
  endfor
  echohl None
endif

" Ensure sure people have Go 1.11.
if str2nr(s:v[15:], 10) < 11
  echohl Error
  echom "gopher.vim needs Go 1.11 or newer; reported version was:"
  for s:l in split(s:v, "\n")
    echom s:l
  endfor
  echohl None
endif

" Make sure people see any warnings.
if s:warn
  sleep 2
endif
