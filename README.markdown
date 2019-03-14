[![This project is considered experimental](https://img.shields.io/badge/Status-experimental-red.svg)](https://arp242.net/status/experimental)
[![Build Status](https://travis-ci.org/Carpetsmoker/gopher.vim.svg?branch=master)](https://travis-ci.org/Carpetsmoker/gopher.vim)
[![codecov](https://codecov.io/gh/Carpetsmoker/gopher.vim/branch/master/graph/badge.svg)](https://codecov.io/gh/Carpetsmoker/gopher.vim)

gopher.vim is a Vim plugin for the Go programming language.

Goals:

- Vendor external dependencies in the plugin.
- Off-load functionality to native Vim features or generic plugins when they
  offer a good user experience.
- Ensure that included commands are well-tested to work with as many possible
  scenarios as possible.

Installation
------------

Installation can be done using the usual suspects. **Vim 8.0.400** or **Neovim
0.2.0** are supported; older versions may work but are not supported.

This plugin **requires Go 1.11** or newer; older versions will *not* work as the
internal vendoring uses modules.

Installation of external tools is done automatically on first usage, but can be
done manually with `:GoSetup`.

Getting started
---------------

Compiling code and running tests is provided with the `go` and `gotest`
compilers. By default the compiler is set to `go` ; you can switch it to
`gotest` with `:comp gotest`.

You can now use `:make` to compile the code. This is a synchronous process. You
can use `:MakeJob` from vim-makejob to run it async, similar to `:GoInstall`,
`:GoTest`, etc.

Running `go generate` or passing `-run` to `:GoTest` can be done by switching
the `makeprg` setting:

	:comp gotest
	:make -run TestX

	:comp go
	:set makeprg=go\ generate
	:make

You could even set `makeprg` to just `go`:

	:set makeprg=go
	:make install
	:make run main.go
	...

All motions that work in vim-go also work in gopher.vim: `[[`, `]]`, `af`, etc.

Overview of over commands:

- `:GoCoverage` – Highlight code coverage.
- `:GoRename`   – Rename identifier under cursor.
- `:GoTags`     – Add or remove struct tags

See [FEATURES.markdown](FEATURES.markdown) for a translation of vim-go features.

See `:help gopher` for the full reference manual.

### Companion plugins

A list of useful companion plugins; this is not an exhaustive list, but rather a
"most useful" list. For many alternatives exist as well; I didn't test all
options.

- [vim-lsc](https://github.com/natebosch/vim-lsc) – LSP client.
  Alternatives:
  [ALE](https://github.com/w0rp/ale),
  [coc.nvim](https://github.com/neoclide/coc.nvim),
  [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim),
  [vim-lsp](https://github.com/prabirshrestha/vim-lsp).

- [vim-makejob](https://git.danielmoch.com/vim-makejob) – Async `:make`.

- [vim-qf](https://github.com/romainl/vim-qf) – Make working with the quickfix
  list/window a bit smoother.

- [errormarker.vim](https://github.com/mh21/errormarker.vim) – Place signs for
  quickfix errors.

- [minisnip](https://github.com/joereynolds/vim-minisnip) – Snippets.
  Alternatives:
  [UltiSnips](https://github.com/sirver/UltiSnips),
  [neosnippet.vim](https://github.com/Shougo/neosnippet.vim).

- [vim-delve](https://github.com/sebdah/vim-delve) – Debugger.
  Alternatives:
  [vim-godebug](https://github.com/jodosha/vim-godebug).

### Other resources

- [Linting your code, the vanilla way](https://gist.github.com/romainl/ce55ce6fdc1659c5fbc0f4224fd6ad29)

### Tips

Some things you can stick in your vimrc:

    augroup my_gopher
        au!

        " Quicker way to make, lint, and test code.
        " au FileType go nnoremap MM :wa<CR>:compiler go<CR>:silent make!<CR>:redraw!<CR>
        " au FileType go nnoremap LL :wa<CR>:compiler golint<CR>:silent make!<CR>:redraw!<CR>
        " au FileType go nnoremap TT :wa<CR>:compiler gotest<CR>:silent make!<CR>:redraw!<CR>

        " Lint on write.
        " autocmd BufWritePost *.go compiler golint | silent make! | redraw!

        " Put a path before GOPATH, to use binaries from there (not recommended
        " unless you have special needs or want to test a modified version of a
        " tool!)
        " autocmd Filetype go let $PATH = $HOME . '/go/bin:' . $PATH

        " Format buffer on write; need to make a motion for the entire buffer to
        " make this work.
        " Use e.g. ALE or Syntastic for a more advanced experience.
        " autocmd BufWritePre *.go
        "             \  let s:save = winsaveview()
        "             \| exe 'keepjumps %!goimports 2>/dev/null || cat /dev/stdin'
        "             \| call winrestview(s:save)
    augroup end


History and rationale
---------------------

I started this repository as a test case for internally vendoring of tools; in
vim-go confusion due to using the wrong version of an external tool (too old or
new) can be common; people have to manually run `:GoUpdateBinaries`, and if an
external tool changes the developers have to scramble to update vim-go to work.

I wanted to experiment with a different approach: it vendors external tools in
the plugin directory and runs those. This way the correct version is always
used. Since this directory is prepended to $PATH other plugins (such as ALE)
will also use these vendored tools.

Overall, this seems to work quite well. Starting with a clean slate made it a
lot easier to develop this as a proof-of-concept.

A second reason was to see how well a Go plugin would work without adding a lot
of "generic" functionality. A lot of effort in vim-go is spent on stuff like
completion, linting, and other features that are "generic" and not specific to
Go. I've never used vim-go's linting or gofmt support, as I found that ALE
always worked better and gives a more consistent experience across filetypes.
Also see [my comments here](https://github.com/fatih/vim-go/issues/2146#issuecomment-471371335).

When vim-go was started in 2014 (based on older work before that) a lot of the
generic tools were non-existent or in their infancy. In the meanwhile these
tools have matured significantly; what were the best choices in 2014 are not
necessarily the best choices today.

gopher.vim is my idea of what "vim-go 2.0" could look like. I hope that a number
of features will get merged back to vim-go, and it's possible this plugin may
get retired eventually; or perhaps it will continue to exist alongside vim-go.
We'll see.

It retains vim-go's commit history. While there have been large changes, it also
retains many concepts and ideas. vim-go is the giant's shoulders on which
gopher.vim stands.

Development
-----------

- It's probably good idea to open an issue first; I really don't like rejecting
  PRs but I like accruing "bloat" even less.

- Please use [.editorconfig](.editorconfig) style settings;
  [vim-editorconfig](https://github.com/sgur/vim-editorconfig) is a good plugin
  to do this automatically.

- The plugin is tested with
  [testing.vim](https://github.com/Carpetsmoker/testing.vim); running the full
  test suite should be as easy as `tvim test ./...` (`tvim lint ./...` for the
  style checkers).

- see [API.markdown](API.markdown) for some API docs (only public functions are
  documented in that file).

- Try to keep the public functions (`gopher#foo#do_something()`) as clean and
  usable as possible; use `s:fun()` for internal stuff, unless you want to test
  it in which case use Python's underscore style: `gopher#python#_private_()`.

- Prefer `printf()` over string concatenation; e.g. `printf('x: %s', ['a
  list'])` will work, whereas `'x: ' . ['a list']` will give you a useless
  error.

- Use `gopher#error()` and `gopher#info()`; don't use `echom` or `echoerr`.

- Prefix variables with the scope (e.g. `l:var` instead of `var`).
