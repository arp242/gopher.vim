" str.vim: Utilities for working with strings.

" Trim leading and trailing whitespace from a string.
fun! gopher#str#trim_space(s) abort
  return gopher#str#trim(a:s, ' \t\r\n')
endfun

" Trim leading and trailing instances of all characters in cutset.
"
" Note that the curset characters need to be regexp-escaped!
fun! gopher#str#trim(s, cutset) abort
  if a:cutset is# ''
    return a:s
  endif

  let l:pat = printf('^[%s]*\(.\{-}\)[%s]*$', a:cutset, a:cutset)
  return substitute(a:s, l:pat, '\1', '')
endfun

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
