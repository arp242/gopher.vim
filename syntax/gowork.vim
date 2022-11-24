if exists('b:current_syntax')
  finish
endif

syntax case match

syn keyword     goworkKeywords     module use replace
syn match       goworkKeywords     /^go/
syn region      goworkComment      start="//" end=/$/ contains=@Spell

syn match       goworkReplace      /=>/  " original => replace

" Semver as 'v1.1.1' and versions as 'v.0.0.0-date-commit'.
syn match       goworkVersion      /\vv\d+\.\d+\.\d+(-\d{14}-[0-9a-f]{12})?%(\+incompatible)?/

hi def link     goworkKeywords     Keyword
hi def link     goworkComment      Comment
hi def link     goworkReplace      Operator
hi def link     goworkVersion      Identifier

let b:current_syntax = 'gowork'
