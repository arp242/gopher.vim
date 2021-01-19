if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

call go#coverage#init#config()

" Commands
command! -nargs=* -complete=customlist,go#coverage#complete GoCoverage call go#coverage#do(<f-args>)
