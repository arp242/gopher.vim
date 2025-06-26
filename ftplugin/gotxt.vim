compiler go

" Autocmd
augroup gopher.vim
  au!
  au BufEnter *.gotxt call gopher#go#set_build_package()
augroup end
