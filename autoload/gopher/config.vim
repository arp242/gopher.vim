" Report if the user enabled a debug flag.
fun! gopher#config#has_debug(flag) abort
  return index(g:gopher_debug, a:flag) >= 0
endfun
