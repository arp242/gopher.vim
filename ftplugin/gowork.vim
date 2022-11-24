if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

call gopher#init#config()
call gopher#init#version()

setlocal noexpandtab

compiler go

augroup gopher.vim
  au!

  au BufEnter go.work call gopher#go#set_build_package()
augroup end
