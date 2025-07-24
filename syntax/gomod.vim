if exists('b:current_syntax')
  finish
endif

syntax case match

syn match       gomodKeywords     /\v^%(go|module|require|exclude|replace|retract|toolchain|godebug|tool|ignore)/
syn region      gomodComment      start="//" end=/$/ contains=@Spell
syn match       gomodIndirect     " // indirect$"
syn match       gomodReplace      /=>/

" Semver as 'v1.1.1' and versions as 'v0.0.0-date-commit'.
syn match       gomodVersion      /\vv\d+\.\d+\.\d+%(-[0-9a-f.-]{12,})?%(\+incompatible)?/

hi def link     gomodKeywords     Keyword
hi def link     gomodComment      Comment
hi def link     gomodReplace      Operator
hi def link     gomodVersion      Identifier
hi def link     gomodIndirect     Keyword

let b:current_syntax = 'gomod'
