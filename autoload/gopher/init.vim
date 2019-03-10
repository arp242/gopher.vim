fun! gopher#init#version_check(v) abort
  return a:v =~# '^go version go1\.\d\d\(\.\d\)\? .\+/.\+$'
endfun

" Check if the requires Vim/Neovim/Go versions are installed.
fun! gopher#init#version()
  let l:msg = ''

  " Make sure it's using a new-ish version of Vim.
  if has('nvim') && !has('nvim-0.2.0')
    let l:msg = 'gopher.vim requires Neovim 0.2.0 or newer'
  " Why this version? Because it's the version that's about a year old at the
  " time of writing, which is a more than reasonable time period to support.
  elseif v:version < 800 || (v:version == 800 && !has('patch1200'))
    let l:msg = 'gopher.vim requires Vim 8.0.1200 or newer'
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

let s:root    = expand('<sfile>:p:h:h:h') " Root dir of this plugin.

" Initialize config values.
fun! gopher#init#config()
  " Ensure that the tools dir is in the PATH and takes precedence over other
  " (possibly outdated) tools.
  let $PATH = s:root . '/tools/bin:' . $PATH

  " Builds tags to add to most commands.
  let g:gopher_build_tags = get(g:, 'gopher_build_tags', '')

  " Flags to add to go install/test/etc. in 'makeprg'
  " Note: changing this at runtime has no effect! Change 'makeprg' directly
  " instead.
  let g:gopher_go_flags = get(g:, 'gopher_go_flags', '-tags "' . g:gopher_build_tags . '"')

  " Syntax highlighting options; possible values:
  "
  " string-spell       Spell check inside strings.
  " string-fmt         Highlight format specifiers inside strings.
  " complex            Highlight complex numbers (off by default as it's a bit
  "                    slow and not used very frequently).
  " fold-block         { .. } blocks.
  " fold-import        import block.
  " fold-varconst      var ( .. ) and const ( .. ) blocks.
  " fold-pkg-comment   The package comment.
  " fold-comment       Any comment that is not the package comment.
  let g:gopher_highlight = get(g:, 'gopher_highlight', [
        \ 'string-spell', 'string-fmt'])

  " Debug flags; possible values:
  "
  " shell     record history of shell commands.
  let g:gopher_debug = get(g:, 'gopher_debug', [])

  "g:gopher_gorename_flags
endfun
