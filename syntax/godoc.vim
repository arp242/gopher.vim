if exists('b:current_syntax')
  finish
endif

syn case match
syn match godocTitle "^\([A-Z][A-Z ]*\)$"

command -nargs=+ HiLink hi def link <args>

HiLink godocTitle Title

delcommand HiLink

let b:current_syntax = 'godoc'
