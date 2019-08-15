if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

" Vim's C indentation doesn't work (mainly due to :=) so define out own.
setlocal nolisp autoindent indentexpr=GoIndent(v:lnum) indentkeys+=<:>,0=},0=)

if exists('*GoIndent')
  finish
endif

fun! GoIndent(n) abort
  let l:pn = prevnonblank(a:n - 1)
  if l:pn is 0  " Top of file.
    return 0
  endif

  " Grab the previous and current line, stripping comments and whitespace.
  let l:pline = trim(substitute(getline(l:pn), '//.*$', '', ''))
  let l:line = trim(substitute(getline(a:n), '//.*$', '', ''))
  let l:indent = indent(l:pn)
  let l:ppn = prevnonblank(a:n - 2)
  if l:ppn > 0
    let l:ppline = trim(substitute(getline(l:ppn), '//.*$', '', ''))
  endif

  " Opened a ( or { block; indent except if we already indented extra because of
  " a multi-line block.
  if l:pline =~# '[({]$' && (l:ppn is 0 || l:ppline !~# '[+\-*/%&|^<>=!.]$')
    let l:indent += shiftwidth()

  " Part of a switch statement.
  elseif l:pline =~# '^\(case .\+\|default\):$'
    let l:indent += shiftwidth()

  " Function invocation split over multiple lines.
  " TODO: two conditions as I think that will be faster, but need to benchmark it!
  elseif l:pline[len(l:pline) - 1] is# ',' && l:pline =~# '\w\k*(.*[^)],$'
    let l:indent += shiftwidth()

  " Ended with an operator.
  elseif l:pline =~# '[+\-*/%&|^<>=!.]$' && (l:ppn is 0 || l:ppline !~# '[+\-*/%&|^<>=!.]$')
    let l:indent += shiftwidth()
  endif

  " Closed a block.
  if l:line =~# '^[)}]'
    let l:indent -= shiftwidth()

  " Closed function call that was extra indented.
  elseif l:pline[len(l:pline) - 1] is# ')' && (l:ppline[len(l:ppline) - 1] is# ',' || l:ppline[len(l:ppline) - 1] is# '(')
    let l:indent -= shiftwidth()

  " Label
  elseif l:line =~# '^\k\+:$'
    let l:indent -= shiftwidth()

  " Switch case.
  elseif l:line =~# '^\(case .*\|default\):$'
    let l:indent -= shiftwidth()

  endif

  return l:indent
endfun
