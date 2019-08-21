" str.vim: Utilities for working with strings.

" Report if s begins with prefix.
fun! gopher#str#has_prefix(s, prefix) abort
  return a:s[:len(a:prefix) - 1] is# a:prefix
endfun

" Report if s ends with suffix.
fun! gopher#str#has_suffix(s, suffix) abort
  return a:s[-len(a:suffix):] is# a:suffix
endfun

" Escape a user-provided string so it can be safely used in regexps.
"
" NOTE: this only works with the default value of 'magic'!
fun! gopher#str#escape(s) abort
  return escape(a:s, '$.*~\')
endfun
