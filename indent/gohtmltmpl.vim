if exists('b:did_indent')
  finish
endif

runtime! indent/html.vim

" Indent Golang HTML templates
setlocal indentexpr=GetGoHTMLTmplIndent(v:lnum)
setlocal indentkeys+==else,=end

if exists('*GetGoHTMLTmplIndent')
  finish
endif

fun! GetGoHTMLTmplIndent(lnum)
  " Get HTML indent
  if exists('*HtmlIndent')
    let l:ind = HtmlIndent()
  else
    let l:ind = HtmlIndentGet(a:lnum)
  endif

  " If need to indent based on last line
  if getline(a:lnum - 1) =~# '^\s*{{-\=\s*\%(if\|else\|range\|with\|define\|block\).*}}'
    let l:ind += shiftwidth()
  endif

  " End of FuncMap block
  if getline(a:lnum) =~# '^\s*{{-\=\s*\%(else\|end\).*}}'
    let l:ind -= shiftwidth()
  endif

  return l:ind
endfunction
