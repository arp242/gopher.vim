" Vim-go compatibility.
"
" Assumes ALE, vim-makejob, and completor.vim

fun! gopher#compat#init()
  " https://github.com/fatih/vim-go/blob/master/ftplugin/go/commands.vim
  command! -nargs=* GoTest     call s:compile('gotest', <f-args>)
  command! -nargs=* GoInstall  call s:compile('go', <f-args>)
  command! GoDef               call completor#do('definition')
  command! GoDoc               call completor#do('doc')

  command! GoInstallBinaries   call gopher#internal#install_all()
  command! GoUpdateBinaries    call gopher#internal#install_all()

  " https://github.com/fatih/vim-go/blob/master/ftplugin/go/mappings.vim
endfun

fun! s:compile(n, ...) abort
  let l:c = b:current_compiler
  exe 'compiler ' . a:n
  exe 'silent lmake ' . join(a:000)
  redraw!
  exe 'compiler ' . l:c
endfun
