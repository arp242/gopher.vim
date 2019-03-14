" import.vim: Implement :GoImport

" Add, modify, or remove imports.
"
" TODO: implement -rm pkg
" TODO: implement adding multiple packages (:GoImport a b, or :GoImport addme -rm removeme)
fun! gopher#import#do(...) abort
  if a:0 is 0
    let l:pkg = expand('<cword>')
  else
    let l:pkg = a:1
  endif

  " TODO: use json:
  " {
  "   "start": 75,
  "   "end": 149,
  "   "code": "import (\n\t\"encoding\"\n\t\"net/url\"\n\t\"reflect\"\n\t\"strconv\"\n\t\"strings\"\n\t\"time\"\n\t\"fm t\"\n)\n\n"
  " }
  let [l:out, l:err] = gopher#system#tool(
        \ ['goimport', '-add', l:pkg], gopher#buf#lines())
  if l:err
    return gopher#error(l:out)
  endif

  let l:outlist = split(l:out, "\n")
  call setline(1, l:outlist)
  if line('$') - 1 > len(l:outlist)
    exe printf('%d,%dd', len(l:outlist), line('$') - 1)
    undojoin
  endif
  normal! j
endfun
