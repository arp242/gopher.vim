if exists('b:current_syntax')
  finish
endif

syntax case match

" Keywords.
syn keyword     gomodKeywords     module require exclude replace

" Comments are always in form of // ...
syn region      gomodComment      start="//" end=/$/ contains=@Spell

" Replace operator.
syn match       gomodReplace      /\v\=\>/

" Semver as 'v1.1.1' and versions as 'v.0.0.0-date-commit'.
syn match       gomodVersion      /\vv\d+\.\d+\.\d+(-\d{14}-[0-9a-f]{12})?/

" // indirect comments after version.
syn match       gomodIndirect     " // indirect$"

hi def link     gomodKeywords     Keyword
hi def link     gomodComment      Comment
hi def link     gomodReplace      Operator
hi def link     gomodVersion      Identifier
hi def link     gomodIndirect     Keyword

let b:current_syntax = 'gomod'
