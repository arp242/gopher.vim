scriptencoding utf-8
call gopher#init#config()

fun! Test_diag() abort
  " Just make sure it doesn't error out.
  silent call gopher#diag#do(0)
endfun
