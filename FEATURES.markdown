Quick overview of features, compared to vim-go.

See [README.markdown](README.markdown) for more detailed information to get
started and `:help gopher` for the full reference manual. This is just a quick
overview.

Building
--------

    :GoInstall                    :make

                                  Change the makeprg to use other build commands.
    :GoBuild                      :setl makeprg=go\ build
    :GoGenerate                   :setl makeprg=go\ generate
    :GoRun                        :setl makeprg=go\ run
                                  NOTE: can also set makeprg to go:
                                    :setl makeprg=go
                                    :make install
                                    :make run main.go
                                  Replace :make with :MakeJob from vim-makejob for async versions.

                                  Testing is done with the gotest compiler:
    :GoTest                       :compiler gotest | :make
    :GoTestCompile                :make -c or :make -c -o/dev/null
    :GoTestFunc                   :make -run ..

    :GoBuildTags                  let g:gopher_build_tags = [..]

Linting
-------

    :GoMetaLinter                 :compiler golint | :make
                                  Or use LSP, ALE, or other generic linting plugin.
    :GoMetaLinterAutoSaveToggle   autocmd

    :GoFmt                        gq: formatprg is set to "gofmt"
    :GoImports                    set formatprg=goimports (see :help ft-go)
    :GoIfErr                      set formatprg=goiferr
    :GoFmtAutoSaveToggle          autocmd or plugin like ALE
    :GoAsmFmtAutoSaveToggle

    :GoLint                       Use gometalinter or golangci-lint
    :GoErrCheck
    :GoVet

Code insight
------------

    :GoDoc                        Use LSP for all of this.
    :GoDecls
    :GoDeclsDir
    :GoDef
    :GoDef
    :GoDefPop
    :GoDefPop
    :GoDefStack
    :GoDefStack
    :GoDefStackClear
    :GoDefStackClear
    :GoDocBrowser
    :GoInfo
    Completion

    :GoFiles                      :!go list ...; probably rare enough to not need a command on its own.
    :GoDeps

    :GoCoverage                   :CoCoverage; would be a good candidte for an external plugin, but
                                               I can't find any good ones.
    :GoCoverageClear              :GoCoverage clear
    :GoCoverageToggle             :GoCoverage toggle

Debugger
--------

    :GoDebugBreakpoint            There are external plugins for this.
    :GoDebugStart
    :GoDebugTest

Code modification
-----------------

    :GoRename                     :GoRename (LSP should be able to do this eventually but it kind of
                                             sucks right now)

    :GoAddTags                    :GoTags
    :GoRemoveTags                 :GoTags -rm

Other
-----

    motions ([[, ]], etc.)        Implemented, but different from vim-go.
    text objects (af, etc.)       Works as vim-go
    :GoPath                       :let $GOPATH = '..'
    :GoTemplateAutoCreateToggle   Easy to use an autocmd.

Not implemented (yet)
---------------------

    :GoCallees                    guru; should probably make one command for this:
    :GoCallers                    :GoGuru callers, or :GoInfo callers
    :GoCallstack
    :GoChannelPeers
    :GoDescribe
    :GoFreevars
    :GoGuruScope
    :GoImplements
    :GoPointsTo
    :GoReferrers
    :GoSameIds
    :GoSameIdsAutoToggle
    :GoSameIdsClear
    :GoSameIdsToggle
    :GoWhicherrs

    :GoKeyify                     keyify
    :GoFillStruct                 fillstruct
    :GoImpl                       impl

    :GoAlternate                  Pretty useful, would prefer external plugin.
    :GoModFmt                     go mod edit -fmt doesn't read from stdin so can't use formatprg
    :GoAutoTypeInfoToggle         Should probably be LSP feature?

    :GoCoverageBrowser            Not sure if it's worth having any of these?
    :GoImport
    :GoImportAs
    :GoDrop
    :GoPlay

N/A
---

    :GoInstallBinaries
    :GoReportGitHubIssue
    :GoUpdateBinaries

vim: cc=35 tw=100
