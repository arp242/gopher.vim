compiler go

" Autocmd
augroup gopher.vim
  au!
  au BufEnter *.gohtml call gopher#go#set_build_package()
augroup end
