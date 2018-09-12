fun! Test_indent() abort
  new
  set filetype=go
  call setline(1, ['package x', '', 'func main() {'])
  exe "normal! Go_\<Esc>"
  call assert_equal("\t_", getline('.'))
endfun
