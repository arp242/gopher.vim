[![This project is considered stable](https://img.shields.io/badge/Status-stable-green.svg)](https://arp242.net/status/stable)
[![Build Status](https://travis-ci.org/arp242/gopher.vim.svg?branch=master)](https://travis-ci.org/arp242/gopher.vim)
[![codecov](https://codecov.io/gh/arp242/gopher.vim/branch/master/graph/badge.svg)](https://codecov.io/gh/arp242/gopher.vim)

gopher.vim is a Vim plugin for the Go programming language.

Goals:

- Vendor external dependencies in the plugin to avoid common version mismatch
  problems.
- Off-load functionality to native Vim features or generic plugins when they
  offer a good user experience. Implement as little as reasonable.
- Ensure that included commands are well-tested to work with as many possible
  scenarios as possible (many vim-go commands are rather rough around the
  edges).

It's currently pre-1.0, but I've been using this as my daily workhorse for the
last half year or so, and it works quite well for me.

See [CHANGES.markdown](CHANGES.markdown) for a more detailed list of changes.

Installation
------------

Installation can be done using the usual methods. You will **need Go 1.11**
and **Vim 8.0.1630** or **Neovim 0.3.2**. Older versions will *not* work due to
missing features.

**Vim 8.1.1513** is recommended, mainly for the popup feature, which vastly
improves the UX for key mappings. [How can I get a newer version of Vim on
Ubuntu?][new] might be useful.

Installation of external tools is done automatically on first usage, but can be
done manually with `:GoSetup`.

[new]: https://vi.stackexchange.com/q/10817/51

Getting started
---------------

Compiling code and running tests is done with the `go` and `gotest` compilers.
By default the compiler is set to `go`; you can switch it to `gotest` with
`:comp gotest`.

You can use `:make` to compile or test the code. This is a synchronous process,
there are plugins to make it run in the background (see "Companion plugins"
below).

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

Setting `g:gopher_install_package` can be useful if you have a `./cmd/proj` you
want to compile:

    autocmd BufReadPre /home/martin/code/proj/*.go
            \ let g:gopher_install_package = 'example.com/proj/cmd/proj'

All motions and text objects that work in vim-go also work in gopher.vim: `[[`,
`]]`, `af`, `ac`, etc.

Overview of other commands:

- `:GoCoverage` – Highlight code coverage.
- `:GoFrob`     – Frob with (modify) code. Also mapped to `;` in normal mode or
                  `<C-k>` in insert mode.
- `:GoGuru`     – Get various information using the `guru` command.
- `:GoImport`   – Add, modify, or remove imports.
- `:GoRename`   – Rename identifier under cursor.
- `:GoTags`     – Add or remove struct tags

See `:help gopher` for the full reference manual.

### Companion plugins

A list of useful companion plugins; this is not an exhaustive list, but rather a
"most useful" list. For many alternatives exist as well; I didn't test all
options.

See [PLUGINS.markdown](PLUGINS.markdown) for some configuration hints for
various plugins.

- [vim-lsc](https://github.com/natebosch/vim-lsc) – LSP client.
  Alternatives:
  [ALE](https://github.com/dense-analysis/ale),
  [coc.nvim](https://github.com/neoclide/coc.nvim),
  [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim),
  [vim-lsp](https://github.com/prabirshrestha/vim-lsp).

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

        " Quicker way to make, lint, and test code.
        " au FileType go nnoremap MM :wa<CR>:compiler go<CR>:silent make!<CR>:redraw!<CR>
        " au FileType go nnoremap LL :wa<CR>:compiler golint<CR>:silent make!<CR>:redraw!<CR>
        " au FileType go nnoremap TT :wa<CR>:compiler gotest<CR>:silent make!<CR>:redraw!<CR>

        " Basic lint on write.
        " autocmd BufWritePost *.go compiler golint | silent make! | redraw!

        " Put a path before GOPATH to use tools from there. Not recommended
        " unless you have special needs or want to test a modified version.
        " autocmd Filetype go let $PATH = $HOME . '/go/bin:' . $PATH

        " Format buffer on write; need to make a motion for the entire buffer to
        " make this work.
        " Use e.g. ALE or Syntastic for a more advanced experience.
        " autocmd BufWritePre *.go
        "             \  let s:save = winsaveview()
        "             \| exe 'keepjumps %!goimports 2>/dev/null || cat /dev/stdin'
        "             \| call winrestview(s:save)
    augroup end

FAQ
---

### I'm missing X from vim-go

That's probably intentional. An important reason for this plugin's existence is
to remove features better handled with native Vim features or generic external
plugins.
See the [feature table in CHANGES.markdown](CHANGES.markdown#feature-table).

If you think there's a good reason for something from vim-go to exist in
gopher.vim then feel free to open an issue with an explanation why existing Vim
features or generic plugins aren't enough.

### Some things that were async in vim-go are no longer, what gives?

Async can be nice but it's also hard. For example the code for `:GoCoverage` is
now 120 lines shorter while also fixing a few bugs and adding features.

There is also a user interface aspect: if I ask Vim to do something then I want
that done now. When it's run in the background feedback is often poor. Is it
still running? Did I miss a message? Who knows, messages are sometimes lost. How
do you cancel a background job from the UI? Often you can't. What if I switch
buffers or modify a file? *Weird Stuff*™ happens.

This doesn't mean I'm against async, just not for every last thing. Some things
in gopher.vim are still async. It's a trade-off. If you have a good case for
something to be async then feel free to open an issue.

### The syntax has fewer colours, it's so boring!

I removed a whole bunch of the extra options as it's hard to maintain and not
all that useful. It doesn't even work all that well because enabling all options
would slow everything down to a crawl and testing all the combinations is
tricky.

So the syntax file in gopher.vim has fewer features, but is also much faster and
easier to maintain. Maybe I'll add some features back once I figure out a better
way to maintain this stuff.

You can still copy vim-go's `syntax/go.vim` file to your `~/.vim/syntax`
directory if you want your Christmas tree back 🎄

### Why do some commands conflict with vim-go? Why not prefix commands with `:Gopher`?

This is what I originally did, and found it annoying as it's so much work to
type, man! Being compatible probably isn't too useful anyway, so I changed it.

Functions, mappings, settings, etc. are all prefixed with `gopher`.

If you really want you can probably `:delcommand` and `:command GopherCommand
...` or some such.

History and rationale
---------------------

I started this repository as a test case for internally vendoring of tools; in
vim-go confusion due to using the wrong version of an external tool (too old or
new) is common; people have to manually run `:GoUpdateBinaries`, and if an
external tool changes the developers have to scramble to update vim-go to work.

I wanted to experiment with a different approach: vendor external tools in the
plugin directory and run those so the correct version is always used. Since this
directory is prepended to $PATH other plugins (such as ALE) will also use these
vendored tools.

Overall, this seems to work quite well. Starting with a clean slate made it a
lot easier to develop this as a proof-of-concept.

A second reason was to see how well a Go plugin would work without adding a lot
of "generic" functionality. A lot of effort in vim-go is spent on stuff like
completion, linting, and other features that are not specific to Go. I've never
used vim-go's linting or gofmt support, as I found that ALE always worked better
and gives a more consistent experience across filetypes. Also see [my comments
here](https://github.com/fatih/vim-go/issues/2146#issuecomment-471371335).

When vim-go was started in 2014 (based on older work before that) a lot of the
generic tools were non-existent or in their infancy. In the meanwhile these
tools have matured significantly; what were the best choices in 2014 are not
necessarily the best choices today.

gopher.vim is my idea of "vim-go 2.0". It retains vim-go's commit history. While
there have been large changes, it also retains some concepts and ideas. vim-go
is the giant's shoulders on which gopher.vim stands.

[govim](https://github.com/myitcv/govim) is another attempt at a modern Go
plugin, and seems to have the same conceptual approach as vim-go: reinvent all
the things. To be honest I didn't look too closely at it (gopher.vim was already
fully functional and correct by the time govim was announced).

Development
-----------

- It's probably good idea to **open an issue first** for features or additions;
  I really don't like rejecting PRs but I like accruing "bloat" even less.

- Please use [.editorconfig](.editorconfig) style settings;
  [edc.vim](https://github.com/arp242/edc.vim) is a good plugin to do this
  automatically.

- The plugin is tested with
  [testing.vim](https://github.com/arp242/testing.vim); running the full test
  suite should be as easy as `tvim test ./...` (`tvim lint ./...` for the style
  checkers).

- Try to keep the public functions (`gopher#foo#do_something()`) as clean and
  usable as possible; use `s:fun()` for internal stuff, unless you want to test
  it in which case use Python's underscore style: `gopher#python#_private_()`.
  See [API.markdown](API.markdown) for some API docs (only public functions are
  documented in that file).

- Prefer `printf()` over string concatenation; e.g. `printf('x: %s', [])` will
  work, whereas `'x: ' . []` will give you a useless error.

- Use `gopher#error()` and `gopher#info()`; don't use `echom` or `echoerr`.

- Always prefix variables with the scope (e.g. `l:var` instead of `var`).

- Use strict comparisons: `if l:foo is# 'str'` instead of `==`. It's like `===`
  from PHP and JavaScript; try `:echo 1 == '1' | :echo 1 is '1'`.

  The `#` ensures that case is always matched; use `is?` for case-insensitive
  matches. Not needed for numbers, but doesn't hurt either.

- Use modern Vim features, don't be too worried about backwards compatibility
  with very old Vim versions that some distros still ship with. Just because
  Debian wants to support everything for 5 years doesn't mean we should.
