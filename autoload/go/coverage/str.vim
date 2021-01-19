" str.vim: Utilities for working with strings.

" Report if s ends with suffix.
fun! go#coverage#str#has_suffix(s, suffix) abort
  return a:s[-len(a:suffix):] is# a:suffix
endfun
