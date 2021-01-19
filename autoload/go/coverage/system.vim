" system.vim: Utilities for working with the external programs and the OS.
"
" Run an external command.
"
" cmd must be a list, one argument per item. Every list entry will be
" automatically shell-escaped
"
" An optional second argument is passed to stdin.
fun! go#coverage#system#run(cmd, ...) abort
  if type(a:cmd) isnot v:t_list
    return go#coverage#error('go#coverage#system#run: must pass a list')
  endif
  if len(a:000) > 1
    return go#coverage#error('go#coverage#system#run: can only pass one optional argument')
  endif

  let l:cmd = go#coverage#system#join(go#coverage#system#sanitize_cmd(a:cmd))

  try
    let l:shell = &shell
    let l:shellredir = &shellredir
    let l:shellcmdflag = &shellcmdflag
    let l:start = reltime()

    if !has('win32') && executable('/bin/sh')
      set shell=/bin/sh shellredir=>%s\ 2>&1 shellcmdflag=-c
    endif

    let l:out = call('system', [l:cmd] + a:000)
    let l:err = v:shell_error
  finally
    let &shell = l:shell
    let &shellredir = l:shellredir
    let &shellcmdflag = l:shellcmdflag
  endtry

  " Remove trailing newline from output; it's rarely useful, and often annoying.
  if l:out[-1:] is# "\n"
    let l:out = l:out[:-2]
  endif

  return [l:out, l:err]
endfun

" Get the path separator for this platform.
fun! go#coverage#system#pathsep() abort
  return has('win32') ? ';' : ':'
endfun

" Join a list of commands to a string, escaping any shell meta characters.
fun! go#coverage#system#join(l, ...) abort
  try
    let l:save = &shellslash
    set noshellslash

    return join(map(copy(a:l), { i, v -> shellescape(l:v, a:0 > 0 ? a:1 : '') }), ' ')
  finally
    let &shellslash = l:save
  endtry
endfun

" Remove v:null from the command, makes it easier to build commands:
"
"   go#coverage#system#run(['gosodoff', (a:error ? '-errcheck' : v:null)])
"
" Without the filter an empty string would be passed.
fun! go#coverage#system#sanitize_cmd(cmd) abort
  return filter(a:cmd, {_, v -> l:v isnot v:null})
endfun
