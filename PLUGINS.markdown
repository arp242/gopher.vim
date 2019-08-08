Configuration hints for various plugins.

Feel free to open a PR to add to this. It's just what I use (or used in the
past).

Also see: https://github.com/golang/go/wiki/gopls#vim--neovim

ALE
---

https://github.com/dense-analysis/ale

    let g:ale_fixers  = {'go': ['goimports']}
    let g:ale_linters = {'go': ['go build', 'gometalinter']}

    let g:gometalinter_fast = ''
          \ . ' --enable=vet'
          \ . ' --enable=errcheck'
          \ . ' --enable=ineffassign'
          \ . ' --enable=goimports'
          \ . ' --enable=misspell'
          \ . ' --enable=lll --line-length=120'
    let g:ale_go_gometalinter_options = '--disable-all --tests' . g:gometalinter_fast . ' --enable=golint'


vim-lsc
-------

https://github.com/natebosch/vim-lsc

    "let g:lsc_server_commands = {'go': 'bingo -diagnostics-style none -enhance-signature-help'}
    " Note: all logs disables as gopls is very verbose.
    let g:lsc_server_commands = {'go': {
                \ 'command': 'gopls -logfile /dev/null serve',
                \ 'log_level': -1,
                \ }}

    let g:lsc_enable_autocomplete = v:false      " Don't complete when typing.
    let g:lsc_enable_diagnostics = v:false       " Don't lint code.
    let g:lsc_preview_split_direction = 'below'  " Show preview at bottom, rather than top.

    let g:lsc_auto_map = {'defaults': v:true, 'SignatureHelp': '<C-k>', 'GoToDefinitionSplit': ''}
    augroup my-lsc
        au!
        au BufNewFile,BufReadPost *
            \  if has_key(get(g:, 'lsc_servers_by_filetype', {}), &filetype) && lsc#server#filetypeActive(&filetype)
            "\     Show function signature in insert mode too (I don't use digraphs).
            \|     inoremap <buffer> <C-k> <C-o>:LSClientSignatureHelp<CR>
            "\     Open in tab, rather than split.
            \|     nnoremap <buffer> <C-w>]     :tab LSClientGoToDefinitionSplit<CR>
            \|     nnoremap <buffer> <C-w><C-]> :tab LSClientGoToDefinitionSplit<CR>
            \|     nnoremap <buffer> gd         :tab LSClientGoToDefinitionSplit<CR>
            \| endif

        " Resize to be as small as possible.
        au WinLeave __lsc_preview__ exe 'resize ' . min([&previewheight, line('$')])
        au User LSCShowPreview      exe 'resize ' . min([&previewheight, line('$')])
    augroup end
