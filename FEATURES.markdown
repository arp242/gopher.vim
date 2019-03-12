Quick overview of features, compared to vim-go.

See [README.markdown](README.markdown) for more detailed information to get
started and `:help gopher` for the full reference manual. This is just a quick
overview.

    BULDING

    :GoBuildTags                  let g:gopher_build_tags = [..]
    :GoInstall                    :compiler go     | :make
    :GoTest                       :compiler gotest | :make
    :GoTestCompile                :make -c
    :GoTestFunc                   :make -run ..

    :GoBuild                      :setl makeprg=go\ build
    :GoGenerate                   :setl makeprg=go\ generate
    :GoRun                        :setl makeprg=go\ run
                                  NOTE: can also set makeprg to go:
                                    :setl makeprg=go
                                    :make install
                                    :make run main.go

    LINTING

    :GoLint                       LSP, ALE, or other generic linting plugin.
    :GoAsmFmtAutoSaveToggle
    :GoErrCheck
    :GoFmt
    :GoFmtAutoSaveToggle
    :GoImports                    formatprg is set to goimports so you can use gq
    :GoMetaLinter                 :compiler golint | :make
    :GoMetaLinterAutoSaveToggle
    :GoModFmt
    :GoVet

    CODE INSIGHT

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

    DEBUGGER

    :GoDebugBreakpoint            There are external plugins for this.
    :GoDebugStart
    :GoDebugTest

    CODE MODIFICATION

    :GoRename                     :GoRename (LSP should be able to do this eventually but it kind of
                                             sucks right now, and my implementation seems to work a
                                             lot better).

    :GoAddTags                    :GoTags
    :GoRemoveTags                 :GoTags -rm

    OTHER

    motions ([[, ]], etc.)        Implemented, but different from vim-go.
    text objects (af, etc.)       Works as vim-go
    :GoPath                       :let $GOPATH = '..'
    :GoTemplateAutoCreateToggle   Easy to use an autocmd.

    NOT IMPLEMENTED (YET)

    :GoAlternate
    :GoAutoTypeInfoToggle
    :GoCallees
    :GoCallers
    :GoCallstack
    :GoChannelPeers
    :GoCoverageBrowser
    :GoDescribe
    :GoDrop
    :GoFillStruct
    :GoFreevars
    :GoGuruScope
    :GoIfErr
    :GoImpl
    :GoImplements
    :GoImport
    :GoImportAs
    :GoKeyify
    :GoPlay
    :GoPointsTo
    :GoReferrers
    :GoSameIds
    :GoSameIdsAutoToggle
    :GoSameIdsClear
    :GoSameIdsToggle
    :GoWhicherrs

    N/A

    :GoInstallBinaries
    :GoReportGitHubIssue
    :GoUpdateBinaries

vim: cc=35 tw=100
