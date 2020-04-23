if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

call gopher#init#config()
call gopher#init#version()

setlocal noexpandtab

compiler go

" Autocmd
augroup gopher.vim
  au!

  au BufEnter go.mod call gopher#go#set_install_package()
augroup end
