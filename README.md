gopher.vim is a Vim plugin for the Go programming language.

The idea is to to provide a "light-weight" experience by offloading
functionality to native Vim features or generic plugins when they offer a good
user experience. It's not hard-core minimalist, but does try to avoid
re-implementing things that are always handled well by other features or plugins
rather than duplicating them.

Installation
------------
Installation can be done using the usual methods. You will need Go 1.21.

Run `:GoSetup` to install the required dependencies.

Quickstart
----------
All gopher.vim mappings start with `;` in normal mode or `<C-k>` in insert mode.
The second letter is identical, so `;t` is `<C-k>t` in insert mode.

You can change this with the `g:gopher_map` setting; see `:help g:gopher_map`
for details.

### Compiling code
Compiling code is done with the `go` compiler (that is, the Vim `:compiler`
feature); you can then use `:make` to run the command in `makeprg` and populate
the quickfix with any errors.

gopher.vim tries to be a bit smart about what to set `makeprg` to: if a
`./cmd/«module-name»` package exists then it will compile that instead of the
current package, and build tags from the current file are automatically added.
There's a bunch of options to tweak the behaviour: see `:help gopher-compilers`
for detailed documentation.

The `;;` mapping will write all files and run `:make`; specifically it runs:

    :silent! :wa<CR>:compiler go<CR>:echo &l:makeprg<CR>:silent make!<CR>:redraw!<CR>

`:make` is a synchronous process, usually Go compile times are fast enough, but
there are plugins to make it run in the background if you want (see "Companion
plugins" below).

### Running tests
Testing is done with the `gotest` compiler; you can run them with `;t` which
will run the current test function if you're inside a test, or tests for the
current package if you're not.

You can pass additional to `:make`; e.g. `:make -failfast`.

### Running lint tools
The `golint` compiler can run lint tools; the error format is compatible with
`golangci-lint`,  `staticcheck`, and `go vet` (other tools may also work, but
are not tested):

    :compiler golint
    :set makeprg=staticcheck
    :make

### Mappings
Map `;t` to run all tests, instead of current:

    " let g:gopher_map = {'_nmap_prefix': '<Leader>', '_imap_prefix': '<C-g>' }

    " Quicker way to make, lint, and test code.
    " au FileType go nnoremap MM :wa<CR>:compiler go<CR>:silent make!<CR>:redraw!<CR>
    " au FileType go nnoremap LL :wa<CR>:compiler golint<CR>:silent make!<CR>:redraw!<CR>
    " au FileType go nnoremap TT :wa<CR>:compiler gotest<CR>:silent make!<CR>:redraw!<CR>

    " au FileType go nmap MM <Plug>(gopher-install)
    " au FileType go nmap TT <Plug>(gopher-test)
    " au FileType go nmap LL <Plug>(gopher-lint)


See `:help gopher_mappings`

### Other commands
All motions and text objects that work in vim-go also work in gopher.vim: `[[`,
`]]`, `af`, `ac`, etc.

Overview of other commands:

    :GoCoverage – Highlight code coverage.
    :GoFrob     – Frob with (modify) code.
    :GoImport   – Add, modify, or remove imports.
    :GoTags     – Add or remove struct tags

Note that many details are different from vim-go; gopher.vim is not intended as
a "drop-in" replacement.

See `:help gopher` for the full reference manual.

### Companion plugins
A list of useful companion plugins; this is not an exhaustive list, but rather a
"most useful" list. For many alternatives exist as well; I didn't test all
options.

- [yegappan/lsp](https://github.com/yegappan/lsp) – LSP client.
  Alternatives:
  [ALE](https://github.com/dense-analysis/ale),
  [coc.nvim](https://github.com/neoclide/coc.nvim),
  [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim),
  [vim-lsp](https://github.com/prabirshrestha/vim-lsp),
  [vim-lsc](https://github.com/natebosch/vim-lsc).

- [neoformat](https://github.com/sbdchd/neoformat) – run gofmt/goimports.
  Alternatives:
  [ALE](https://github.com/dense-analysis/ale).

- [vim-makejob](https://git.danielmoch.com/vim-makejob) – Async `:make`.
  Alternatives:
  [vim-dispatch](https://github.com/tpope/vim-dispatch)

- [switchy.vim](https://github.com/arp242/switchy.vim) – Switch to `_test.go`
  files. Alternatives:
  [vim-altr](https://github.com/kana/vim-altr),
  [alternate-lite](https://github.com/LucHermitte/alternate-lite),
  [FSwitch](https://www.vim.org/scripts/script.php?script_id=2590),
  [a.vim](https://www.vim.org/scripts/script.php?script_id=31).

- [vim-qf](https://github.com/romainl/vim-qf) – Make working with the quickfix
  list/window a bit smoother.

- [errormarker.vim](https://github.com/mh21/errormarker.vim) – Place signs for
  quickfix errors.

- [minisnip](https://github.com/joereynolds/vim-minisnip) – Snippets.
  Alternatives:
  [lazy.vim](https://github.com/arp242/lazy.vim),
  [UltiSnips](https://github.com/sirver/UltiSnips),
  [neosnippet.vim](https://github.com/Shougo/neosnippet.vim),
  [sonictemplate-vim](https://github.com/mattn/sonictemplate-vim).

- [vim-delve](https://github.com/sebdah/vim-delve) – Debugger.
  Alternatives:
  [vim-godebug](https://github.com/jodosha/vim-godebug),
  [vimspector](https://github.com/puremourning/vimspector).


### Other resources

- [Linting your code, the vanilla way](https://gist.github.com/romainl/ce55ce6fdc1659c5fbc0f4224fd6ad29)

### Tips

Some things you can stick in your vimrc:

    augroup my_gopher
        au!

        " Basic lint on write.
        " autocmd BufWritePost *.go compiler golint | silent make! | redraw!

        " Format buffer on write; need to make a motion for the entire buffer to
        " make this work.
        " Use e.g. ALE or Syntastic for a more advanced experience.
        " autocmd BufWritePre *.go
        "             \  let s:save = winsaveview()
        "             \| exe 'keepjumps %!goimports 2>/dev/null || cat /dev/stdin'
        "             \| call winrestview(s:save)

        " Compile without cgo unless explicitly enabled.
        " autocmd BufReadPre *.go if $CGO_ENABLED is# '' | let $CGO_ENABLED=0 | endif
    augroup end
