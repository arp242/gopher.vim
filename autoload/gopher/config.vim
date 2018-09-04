" Flags to add to go install/test/etc. in 'makeprg'
" Note: changing this at runtime has no effect! Change 'makeprg' directly
" instead.
let gopher#config#go_flags = get(g:, 'gopher_go_flags', '')

" Add commands and mappings which are roughly compatible with vim-go.
let gopher#config#vimgo_compat = get(g:, 'gopher_vimgo_compat', 0)

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
let gopher#config#highlight = get(g:, 'gopher_config_highlight', [
      \ 'string-spell', 'string-fmt'])

" Debug flags; possible values:
"
" shell     record history of shell commands.
let gopher#config#debug = get(g:, 'gopher_debug', [])

" Report if the user enabled a debug flag.
fun! gopher#config#has_debug(flag)
  return index(get(g:, 'gopher_debug', []), a:flag) >= 0
endfun
