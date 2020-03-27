" init.vim: Initialisation of the plugin.

" Check if the requires Vim/Neovim/Go versions are installed.
fun! gopher#init#version() abort
  let l:msg = ''

  " Make sure it's using a new-ish version of Vim.
  if has('nvim') && !has('nvim-0.3.2')
    let l:msg = 'gopher.vim requires Neovim 0.3.2 or newer'
  elseif v:version < 800 || (v:version == 800 && !has('patch1630'))
    let l:msg = 'gopher.vim requires Vim 8.0.1630 or newer'
  endif

  " Ensure people have Go installed correctly.
  let l:v = system('go version')
  if v:shell_error > 0
    let l:msg = "Go doesn't seem installed correctly? 'go version' failed with:\n" . l:v
  else
      let l:msg = gopher#init#version_check(l:v)
  endif

  if l:msg isnot# ''
    for l:l in split(l:msg, "\n")
      echoerr l:l
    endfor
  endif
endfun

" Check if the 'go version' output is a version we support.
fun! gopher#init#version_check(v) abort
  for l:line in split(a:v, '\n')
    if l:line !~# '^go version \(devel\|go1\.\d\d\(\.\d\d\?\)\?\) .\+/.\+$'
      continue
    endif

    if l:line[:15] isnot# 'go version devel' && str2nr(l:line[15:], 10) < 11
      return "gopher.vim needs Go 1.11 or newer; reported version was:\n" . l:line
    endif

    return ''
  endfor

  return "gopher.vim needs Go 1.11 or newer; reported version was:\n" . a:v
endfun

let s:root    = expand('<sfile>:p:h:h:h') " Root dir of this plugin.
let s:config_done = 0

" Initialize config values.
fun! gopher#init#config() abort
  if s:config_done
    return
  endif

  " Ensure that the tools dir is in the PATH and takes precedence over other
  " (possibly outdated) tools.
  let $PATH = s:root . '/tools/bin' . gopher#system#pathsep() . $PATH

  " Set defaults.
  let g:gopher_build_tags     = get(g:, 'gopher_build_tags', [])
  let g:gopher_build_flags    = get(g:, 'gopher_build_flags', [])
        \ + (len(g:gopher_build_tags) > 0 ? ['-tags', join(g:gopher_build_tags, ' ')] : [])
  let g:gopher_highlight      = get(g:, 'gopher_highlight', ['string-spell', 'string-fmt'])
  let g:gopher_debug          = get(g:, 'gopher_debug', [])
  let g:gopher_tag_transform  = get(g:, 'gopher_tag_transform', 'snakecase')
  let g:gopher_tag_default    = get(g:, 'gopher_tag_default', 'json')
  let g:gopher_tag_complete   = get(g:, 'gopher_tag_complete', ['db', 'json', 'json,omitempty', 'yaml'])

  call s:map()

  let s:config_done = 1
endfun

fun! s:map() abort
  if exists('g:gopher_map') && g:gopher_map is 0
    return
  endif

  let l:settings = {
        \ '_default':     1,
        \ '_popup':       exists('*popup_create') && exists('*popup_close'),
        \ '_nmap_prefix': ';',
        \ '_imap_prefix': '<C-k>',
        \ '_imap_ctrl':   1,
    \ }
  let l:maps = {
        \ 'error':     'e',
        \ 'if':        'i',
        \ 'implement': 'm',
        \ 'return':    'r',
    \ }

  if !exists('g:gopher_map')
    let g:gopher_map = extend(l:settings, l:maps)
    return
  endif

  let g:gopher_map = extend(l:settings, g:gopher_map)
  if g:gopher_map['_default']
    call extend(g:gopher_map, l:maps)
  endif
endfun
