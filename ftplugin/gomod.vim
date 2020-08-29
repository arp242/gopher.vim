if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

call gopher#init#config()
call gopher#init#version()

setlocal noexpandtab

compiler go

command! -nargs=* GoModReplace call gopher#mod#replace(<f-args>)
