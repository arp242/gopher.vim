if exists('b:current_syntax')
  finish
endif

syntax case match

syn keyword     gomodKeywords     module require exclude replace
syn match       gomodKeywords     /^go/
syn region      gomodComment      start="//" end=/$/ contains=@Spell
syn match       gomodIndirect     " // indirect$"
syn match       gomodReplace      /=>/  " original => replace

" Semver as 'v1.1.1' and versions as 'v.0.0.0-date-commit'.
syn match       gomodVersion      /\vv\d+\.\d+\.\d+(-\d{14}-[0-9a-f]{12})?%(\+incompatible)?/

hi def link     gomodKeywords     Keyword
hi def link     gomodComment      Comment
hi def link     gomodReplace      Operator
hi def link     gomodVersion      Identifier
hi def link     gomodIndirect     Keyword

let b:current_syntax = 'gomod'
