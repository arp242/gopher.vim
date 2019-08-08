" pkg.vim: Utilities for working with Go packages.

let s:std = []

" List all stdlib Go packages.
fun! gopher#pkg#list_std() abort
  " This is not going to change, so cache it.
  if len(s:std) is 0
    let [l:out, l:err] = gopher#system#run(['go', 'list', 'std'])
    if l:err
      call gopher#error(l:out)
      return []
    endif
    let s:std = split(l:out, "\n")
  endif
  return s:std
endfun

" List all Go packages and dependencies for the current path.
fun! gopher#pkg#list_deps() abort
  let [l:out, l:err] = gopher#system#run(['go', 'list', '-deps', './...'])
  if l:err
    call gopher#error(l:out)
    return []
  endif
  return split(l:out, "\n")
endfun

" List all interfaces for a Go package.
"
" TODO: cache.
fun! gopher#pkg#list_interfaces(pkg) abort
  let [l:out, l:err] = gopher#system#run(['go', 'doc', a:pkg])
  if l:err
    call gopher#error(l:out)
    return []
  endif

  return map(filter(split(l:out, "\n"), {_, v -> l:v  =~# '^type \k* interface'}),
        \ {_, v -> split(l:v, " ")[1]})
endfun
