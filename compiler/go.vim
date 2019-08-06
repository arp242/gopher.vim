if exists('g:current_compiler')
  finish
endif
let g:current_compiler = 'go'
let s:save_cpo = &cpoptions
set cpoptions-=C

" TODO: can probably automate the gopher_install_package better with some "go
" list"-fu.
let &l:makeprg = printf('go install %s %s',
      \ gopher#system#join(get(g:, 'gopher_build_flags', [])),
      \ get(g:, 'gopher_install_package', ''))

" TODO: this error isn't recognized:
" # a
" runtime.main_main·f: function main is undeclared in the main package

setl errorformat =%-G#\ %.%#                   " Ignore lines beginning with '#' ('# command-line-arguments' line sometimes appears?)
setl errorformat+=%-G%.%#panic:\ %m            " Ignore lines containing 'panic: message'
setl errorformat+=%Ecan\'t\ load\ package:\ %m " Start of multiline error string is 'can\'t load package'
setl errorformat+=%A%f:%l:%c:\ %m              " Start of multiline unspecified string is 'filename:linenumber:columnnumber:'
setl errorformat+=%A%f:%l:\ %m                 " Start of multiline unspecified string is 'filename:linenumber:'
setl errorformat+=%C%*\\s%m                    " Continuation of multiline error message is indented
setl errorformat+=%-G%.%#                      " All lines not matching any of the above patterns are ignored

let &cpoptions = s:save_cpo
unlet s:save_cpo
