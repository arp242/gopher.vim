if exists('b:current_syntax')
  finish
endif

" TODO: finish all the other syntax stuff.
" https://godoc.org/golang.org/x/tools/present

syn match goPresentSection       /^\* .*$/
syn match goPresentSubSection    /^\*\{2,} .*$/

hi def link goPresentSection     Identifier
hi def link goPresentSubSection  PreProc
