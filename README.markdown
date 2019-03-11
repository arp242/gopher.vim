[![Build Status](https://travis-ci.org/Carpetsmoker/gopher.vim.svg?branch=master)](https://travis-ci.org/Carpetsmoker/gopher.vim)
[![codecov](https://codecov.io/gh/Carpetsmoker/gopher.vim/branch/master/graph/badge.svg)](https://codecov.io/gh/Carpetsmoker/gopher.vim)

gopher.vim is an experimental Vim plugin for the Go programming language.

Goals:

- Vendor external dependencies in the plugin.

- Off-load functionality to native Vim features or generic plugins when they
  offer a good user experience.

- Ensure that included commands are well-tested to work with as many possible
  scenarios as possible.

This plugins **requires** Go 1.11 or newer and a fairly new version of Vim
(probably 8.0.something) or Neovim.

Companion plugins
-----------------

This is a current list of companion plugins. For many alternatives exist as
well; I didn't test all options; this is just what I happen to be using at the
time.

- [vim-lsc](https://github.com/natebosch/vim-lsc) – LanguageServer client.
  Alternatives:
  [ALE](https://github.com/w0rp/ale),
  [coc.nvim](https://github.com/neoclide/coc.nvim),
  [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim),
  [vim-lsp](https://github.com/prabirshrestha/vim-lsp).

- [vim-makejob](https://github.com/djmoch/vim-makejob) – Async `:make`.
