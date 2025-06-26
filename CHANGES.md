Quick overview of changes and features, compared to vim-go.

See [README.md](README.md) for more detailed information to get started and
`:help gopher` for the full reference manual. This is just a quick overview.

Changes from vim-go
-------------------

Some of the biggest changes/improvements from vim-go (not a comprehensive list):

- No need to run `:GoInstallBinaries` or `:GoUpdateBinaries`. It's all done
  automatically on first command use.

- :`GoInstall`, `:GoTest`, etc. are now implemented as a compiler. This is
  essentially the same in most respects, except that it doesn't re-implement
  quite a bit of native Vim features. It's also a bit smarter about which
  package to build and passing build tags.

- `:GoImpl` is now `:GoFrob implements`. All code change commands are now behind
  one `:GoFrob` command. They're also mapped to `;[letter]` in normal mode, and
  `<C-k>[letter]` in insert mode. `implements` is `;m` and `<C-k>m`.

  There are a number of improvements:

  - It just needs the interface name. I always thought it was very confusing
    before with the reciever name etc. If you want a different name then it
    should be easy to `:s/../../`.
  - Don't generate methods that already exist.
  - Add return with zero values and comment, instead of panic.
  - Accept more than one interface (`:GoFrob implements io.Reader io.Writer`).

- `:GoIfErr` is now `:GoFrob error` and has a few fixes: the code is placed
  smarter (e.g. not outside of a function), is properly indented, has better
  cursor positioning, etc. Also works via `;e` and `<C-k>e`.

- `:GoRename` is still the same, with some minor improvements mostly relating to
  race conditions where the buffer on disk was changed but Vim didn't pick up on
  it, etc. Overall, it should have a smoother experience.

- `:GoCoverage*` commands are just one `:GoCoverage` command. The most notable
  improvement is that all buffers are now updated: if you run `:GoCoverage` on
  `a.go` and you also have `b.go` open, then `b.go` will be highlighted as well.

- `GoImport` was completely reimplemented using an external tool instead of
  regexps; it's smarter about various things, such as replacing `text/template`
  with `html/template`.

- Several improvements to the syntax highlighting; it adds a few minor
  highlights (e.g. struct tags, highlight erroneous `go:generate`, highlight cgo
  directives, few more), but also removes a few features that were very slow,
  complex, and not even 100% correct in all cases.

  The syntax highlighting is also much faster (even faster than the standard one
  in Vim) and should break less often:

      TOTAL      COUNT
      0.113017   101215     gopher.vim
      0.129921   114903     vim runtime
      0.306453   141057     vim-go

- Indentation is a bit smarter.

- Template syntax and filetypes are loaded for `.gohtml` (`.tmpl` in vim-go) and
  `.gotxt` (not in vim-go) files. This is that Gogland uses, and seems more
  useful to me. Also renamed the filetypes to `gohtml` and `gotxt` instead of
  `gohtmltmpl` and `gotxttmpl`.

- All the `go guru` commands are now in just one command: `:GoGuru`. Use e.g.
  `:GoGuru whicherrs` instead of `:GoWhichErrs`. Note: `guru` doesn't always
  work well with modules, and `gopls` is expected to replace much of it
  eventually.

- `:GoAddTags` and `:GoRemoveTags` is now `:GoTags`. Use `:GoTags -rm json` to
  remove a tag.

- Many small improvements in edge cases and code quality.

Features not in vim-go
----------------------

- Use `:GoDiag` to get useful debugging information. Even more useful with
  `g:gopher_debug = ['commands']` to record the input/output of all commands
  that are run.

- Normal and insert mode mappings. Pressing `;` in normal mode or `<C-k>` in
  insert mode gives you a popup menu (Vim 8.1.1513 recommended). See `:help
  gopher-mappings` for details.

- `:GoFrob return` (`;r`/`<C-k>r`) generates a blank return statement with zero
  values.

- `:GoFrob if` (`;i` / `<C-k>i`) toggles between single-line `if a := f(); a`
  and normal `if` statements.

- Basic support for present files.

Feature table
-------------

vim-go on left, gopher.vim on right.

### Building

    :GoInstall                    :make
    :GoBuild                      :setl makeprg=go\ build | :make
    :GoGenerate                   :setl makeprg=go\ generate | :make
    :GoRun                        :setl makeprg=go\ run | :make

                                  NOTE: can also set makeprg to go:
                                    :setl makeprg=go
                                    :make install
                                    :make run main.go
                                  Replace :make with :MakeJob from vim-makejob for async versions.

    :GoTest                       :compiler gotest | :make
    :GoTestCompile                :make -c or :make -c -o/dev/null
    :GoTestFunc                   :make -run ..

    :GoBuildTags                  let g:gopher_build_tags = [..], or b:gopher_build_tags

### Linting

    :GoMetaLinter                 :compiler golint | :make
                                  Or use LSP, ALE, or other generic linting plugin.
    :GoMetaLinterAutoSaveToggle   autocmd

    :GoFmt                        = (equalprg is set to gofmt), also LSP feature
    :GoImports                    :set equalprg=goimports (see :help ft-go), also LSP feature
    :GoFmtAutoSaveToggle          autocmd or plugin like ALE
    :GoAsmFmtAutoSaveToggle       ⤶

    :GoLint                       Use gometalinter or golangci-lint
    :GoErrCheck                   ⤶
    :GoVet                        ⤶

### Code insight

    :GoDoc                        Use LSP for all of this.
    :GoDecls                      ⤶
    :GoDeclsDir                   ⤶
    :GoDef                        ⤶
    :GoDef                        ⤶
    :GoDefPop                     ⤶
    :GoDefPop                     ⤶
    :GoDefStack                   ⤶
    :GoDefStack                   ⤶
    :GoDefStackClear              ⤶
    :GoDefStackClear              ⤶
    :GoDocBrowser                 ⤶
    :GoInfo                       ⤶
    Insert mode completion        ⤶
    :GoSameIdsAutoToggle          ⤶
    :GoSameIdsClear               ⤶
    :GoSameIdsToggle              ⤶
    :GoAutoTypeInfoToggle         ⤶

    :GoFiles                      :!go list ...; probably rare enough to not need a command on its own.
    :GoDeps                       ⤶

    :GoCoverage                   :CoCoverage; would be a good candidate for an external plugin, but
                                               I can't find any good ones.
    :GoCoverageClear              :GoCoverage clear
    :GoCoverageToggle             :GoCoverage toggle

    :GoCallees                    These are all guru commands, and can be used with :GoGuru
    :GoCallers                    e.g. :GoGuru callers, :GoGuru whicherrs, etc.
    :GoCallstack                  ⤶
    :GoChannelPeers               ⤶
    :GoDescribe                   ⤶
    :GoFreevars                   ⤶
    :GoImplements                 ⤶
    :GoPointsTo                   ⤶
    :GoReferrers                  ⤶
    :GoSameIds                    ⤶
    :GoWhicherrs                  ⤶

    :GoGuruScope                  :let gopher_guru_scope = '..' or :GoGuru -scope .. command

### Debugger

    :GoDebugBreakpoint            There are external plugins for this.
    :GoDebugStart                 ⤶
    :GoDebugTest                  ⤶

### Code modification

    :GoRename                     :GoRename (LSP should be able to do this eventually but it kind of
                                             sucks right now)

    :GoAddTags                    :GoTags
    :GoRemoveTags                 :GoTags -rm

    :GoImport                     :GoImport foo
    :GoImportAs                   :GoImport foo:alias
    :GoDrop                       :GoImport -rm foo

    :GoIfErr                      :GoFrob if; also mapped to ;e (normal) and <C-k>e (insert)
    :GoImpl                       :GoFrob implement; also mapped to ;m (normal) and <C-k>m (insert)
    :GoFillStruct                 :GoFrob fillstruct and ;f / <C-k>f mappings

### Other

    :GoInstallBinaries            Managed automatically; :GoSetup if you want.
    :GoUpdateBinaries             ⤶
    motions ([[, ]], etc.)        Implemented, but different from vim-go.
    text objects (af, etc.)       Works as vim-go
    :GoPath                       :let $GOPATH = '..'
    :GoTemplateAutoCreateToggle   Easy to use an autocmd.
    :GoReportGitHubIssue          :GoDiag report
    :GoAlternate                  Several external plugins for this.

### Not implemented

    :GoKeyify                     Doesn't work well with Go Modules, build tags; would be good to
                                  have, but tool is 'too broken' atm.
    :GoCoverageBrowser            Not sure if it's worth having? Could add ":GoCoverage browser" if there's demand.
    :GoPlay                       ⤶ can also be done by external "send to pastebin"-like plugin.
    :GoModFmt                     go mod edit -fmt doesn't read from stdin so can't use formatprg:
                                  https://github.com/golang/go/issues/28118
                                  Can modify after write and re-read; not sure how often this command is used.
