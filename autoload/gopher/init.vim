" init.vim: Initialisation of the plugin.

" Check if the requires Vim/Neovim/Go versions are installed.
fun! gopher#init#version() abort
  let l:msg = ''

  " Make sure it's using a new-ish version of Vim.
  if has('nvim') && !has('nvim-0.2.0')
    let l:msg = 'gopher.vim requires Neovim 0.2.0 or newer'
  " Why this version? Because it's the version that's about two years old at the
  " time of writing, which is a more than reasonable time period to support.
  elseif v:version < 800 || (v:version == 800 && !has('patch0400'))
    let l:msg = 'gopher.vim requires Vim 8.0.0400 or newer'
  endif

  " Ensure people have Go installed correctly.
  let l:v = system('go version')
  if v:shell_error > 0 || !gopher#init#version_check(l:v)
    let l:msg = "Go doesn't seem installed correctly? 'go version' failed with:\n" . l:v
  " Ensure sure people have Go 1.11.
  elseif str2nr(l:v[15:], 10) < 11
    let l:msg = 'gopher.vim needs Go 1.11 or newer; reported version was:\n' . l:v
  endif

  if l:msg isnot# ''
    echohl Error
    for l:l in split(l:msg, "\n")
      echom l:l
    endfor
    echohl None

    " Make sure people see any warnings.
    sleep 2
  endif
endfun

" Check if the 'go version' output is a version we support.
fun! gopher#init#version_check(v) abort
  return a:v =~# '^go version go1\.\d\d\(\.\d\d\?\)\? .\+/.\+$'
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
        \ + (len(get(g:, 'gopher_build_tags', [])) > 0 ? ['-tags', join(g:gopher_build_tags, ' ')] : [])
  let g:gopher_highlight      = get(g:, 'gopher_highlight', ['string-spell', 'string-fmt'])
  let g:gopher_debug          = get(g:, 'gopher_debug', [])
  let g:gopher_tag_transform  = get(g:, 'gopher_tag_transform', 'snakecase')
  let g:gopher_tag_default    = get(g:, 'gopher_tag_default', 'json')
  let g:gopher_gorename_flags = get(g:, 'gopher_gorename_flags', [])
  " TODO: respect _detault
  let g:gopher_map =            get(g:, 'gopher_map', {
                                        \ '_default': 1,
                                        \ '_popup': exists('*popup_create') && exists('*popup_close'),
                                        \ '_nmap_prefix': ';',
                                        \ '_imap_prefix': '<C-k>',
                                        \ '_imap_ctrl': 1,
                                        \ 'if':     'i',
                                        \ 'return': 'r',
                                        \ 'error':  'e',
                                        \ 'implement':  'm',
                                        \ })

  let s:config_done = 1
endfun
