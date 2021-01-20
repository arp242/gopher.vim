" str.vim: Utilities for working with strings.

" Report if s begins with prefix.
fun! go#coverage#str#has_prefix(s, prefix) abort
  return a:s[:len(a:prefix) - 1] is# a:prefix
endfun

" Report if s ends with suffix.
fun! go#coverage#str#has_suffix(s, suffix) abort
  return a:s[-len(a:suffix):] is# a:suffix
endfun

" Escape a user-provided string so it can be safely used in regexps.
"
" NOTE: this only works with the default value of 'magic'!
fun! go#coverage#str#escape(s) abort
  return escape(a:s, '$.*~\')
endfun

" URL encode a string.
fun! go#coverage#str#url_encode(s) abort
    return substitute(a:s, '[^A-Za-z0-9_.~-]',
          \ '\="%".printf(''%02X'', char2nr(submatch(0)))', 'g')
endfun

" Fold multiple whitespace to a single space.
fun! go#coverage#str#fold_space(s) abort
  return substitute(a:s, '\s\+', ' ', 'g')
endfun
