" import.vim: Implement :GoImport

" Complete package names.
"
" TODO: for modules: list std and modules. For GOPATH: list whatever is in there.
" TODO: also complete -rm, -add, -replace, and be a bit smarter about where the
" cursor is.
fun! gopher#import#complete(lead, cmdline, cursor) abort
  return filter(uniq(sort(gopher#pkg#list_deps() + gopher#pkg#list_std())),
        \ {_, v -> strpart(l:v, 0, len(a:lead)) is# a:lead})
endfun

" Add, modify, or remove imports.
fun! gopher#import#do(...) abort

  let [l:out, l:err] = gopher#system#tool(['goimport', '-json'] +
        \ (a:0 is 0 ? [expand('<cword>')] : (a:1[0] is# '-' ? a:000 : ['-add'] + a:000)),
        \ gopher#buf#lines())
  if l:err
    return gopher#error(l:out)
  endif

  " TODO: use json:
  " {
  "   "start": 75,
  "   "end": 149,
  "   "code": "import (\n\t\"encoding\"\n\t\"net/url\"\n\t\"reflect\"\n\t\"strconv\"\n\t\"strings\"\n\t\"time\"\n\t\"fm t\"\n)\n\n"
  " }

  try
    let l:json = json_decode(l:out)
  catch
    return gopher#error(l:out)
  endtry
  "call gopher#frob#replace(l:json['start'], l:json['end'], split(l:json['code'], "\n"))

  " let l:outlist = split(l:out, "\n")
  " call setline(1, l:outlist)
  " if line('$') - 1 > len(l:outlist)
  "   exe printf('%d,%dd', len(l:outlist), line('$') - 1)
  "   undojoin
  " endif
  " normal! j
endfun
