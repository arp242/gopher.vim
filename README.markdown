[![Build Status](https://travis-ci.org/Carpetsmoker/gopher.vim.svg?branch=master)](https://travis-ci.org/Carpetsmoker/gopher.vim)
[![codecov](https://codecov.io/gh/Carpetsmoker/gopher.vim/branch/master/graph/badge.svg)](https://codecov.io/gh/Carpetsmoker/gopher.vim)

gopher.vim is an experimental Vim plugin for the Go programming language.

It is a testbed for some ideas I have; some may get merged back in to vim-go,
others may not. I'm not sure yet what will work and what won't.

Goals are:

- See if some vim-go features can be replaced with native Vim features. For
  example, I'm not sure if `:GoInstall`, `:GoBuild`, `:GoTest`, etc. add that
  much over setting a compiler and running `:make`. Plugins such as vim-makejob
  provide async `:make` and work quite well.

- Investigate how mature the Go support is in other plugins, instead of
  implementing it in vim-go. Perhaps the best example are the linting and gofmt
  features: ALE seems to handle those a lot better than vim-go; and for users
  running ALE is more beneficial as well, since it will give them a more
  consistent experience across filetypes (instead of having to learn
  commands/mappings for every filetype).

The reason for this is more code means more bugs and higher maintenance burden.
Vim is not an easy editor to program, and I'd rather not re-invent the wheel if
existing Vim features or plugins already work well and handle all obscure corner
cases.

For the most part, this plugin works, but it is *experimental*. It also requires
Go 1.11 and a fairly new version of Vim (probably 8.0.something).

---

- [ALE][ALE]             – Syntax checking; `gofmt`/`goimports`; integration
                           with [go-langserver][go-langserver] for "go to
                           definition", completion.
- [vim-makejob][makejob] – Async `:make`.

Configuration:

    " ALE
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

[go-langsever]: https://github.com/sourcegraph/go-langserver
[ALE]: https://github.com/w0rp/ale/
[makejob]: https://github.com/djmoch/vim-makejob
