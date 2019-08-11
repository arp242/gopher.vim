" import.vim: Implement :GoImport

" Complete package names.
fun! gopher#import#complete(lead, cmdline, cursor) abort
  let l:p = gopher#compl#prev_word(a:cmdline, a:cursor)
  if (l:p is# 'GoImport' || l:p[0] is# '-') && gopher#compl#word(a:cmdline, a:cursor)[0] isnot '-'
    let l:list = gopher#pkg#list_importable()
  else
    let l:list = ['-add', '-replace', '-rm']
  endif

  return gopher#compl#filter(a:lead, l:list)
endfun

" Add, modify, or remove imports.
fun! gopher#import#do(...) abort
  let [l:out, l:err] = gopher#system#tool(['goimport', '-json'] +
        \ (a:0 is 0 ? [expand('<cword>')] : (a:1[0] is# '-' ? a:000 : ['-add'] + a:000)),
        \ gopher#buf#lines())
  if l:err
    return gopher#error(l:out)
  endif

  try
    let l:json = json_decode(l:out)
  catch
    return gopher#error(l:out)
  endtry

  call gopher#buf#replace(l:json['start'], l:json['end'], l:json['code'])
endfun
