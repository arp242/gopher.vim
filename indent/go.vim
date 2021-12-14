if exists('b:did_indent')
  finish
endif
let b:did_indent = 1

" Vim's C indentation doesn't work (mainly due to :=) so define out own.
setlocal nolisp autoindent indentexpr=GoIndent(v:lnum) indentkeys+=<:>,0=},0=)

if exists('*GoIndent')
  finish
endif

" TODO: this will de-indent if you insert a ":" on the second line:
"
"   gctest.StoreHits(ctx, t, false,
"       goatcounter.Hit{Site: sID, Path: "/test", CreatedAt: now},
"   )

fun! GoIndent(n) abort
  let pn = prevnonblank(a:n - 1)
  if pn is 0  " Top of file.
    return 0
  endif

  " Grab the previous and current line, stripping comments and whitespace.
  let pline  = trim(substitute(getline(pn), '//.*$', '', ''))
  let line   = trim(substitute(getline(a:n), '//.*$', '', ''))

  " Start with the indentation of the previous (non-blank) line.
  let indent = indent(pn)
  let ppn = prevnonblank(a:n - 2)
  if ppn > 0
    let ppline = trim(substitute(getline(ppn), '//.*$', '', ''))
  endif

  " Opened a ( or { block; indent except if we already indented extra because of
  " a multi-line block.
  if pline =~# '[({]$' && (ppn is 0 || ppline !~# '[+\-*/%&|^<>=!.]$')
    let indent += shiftwidth()

  " Part of a switch statement.
  elseif pline =~# '^\(case .\+\|default\):$'
    let indent += shiftwidth()

  " Function invocation split over multiple lines.
  " \h        Head of word
  " \w*       0 or more words
  " (         (
  " .*        Anything
  " [^)]      Anything except )
  " ,         Command
  " $         End of line

  " TODO: two conditions as I think that will be faster, but need to benchmark it!
  " TODO: #21, 2nd comment
  " elseif pline[len(pline) - 1] is# ',' && pline =~# '\h\w*(.*[^)],$'
  "   let indent += shiftwidth()

  " Ended with an operator.
  elseif pline =~# '[+\-*/%&|^<>=!.]$' && (ppn is 0 || ppline !~# '[+\-*/%&|^<>=!.]$')
    let indent += shiftwidth()
  endif

  " Closed a block.
  if line =~# '^[)}]'
    let indent -= shiftwidth()

  " Closed function call that was extra indented.
  elseif pline[len(pline) - 1] is# ')' && (ppline[len(ppline) - 1] is# ',' || ppline[len(ppline) - 1] is# '(')
    let indent -= shiftwidth()

  " Label
  " TODO: Breaks struct fields, see #21, 1st comment
  " elseif line =~# '^\k\+:$'
  "   let indent -= shiftwidth()

  " Switch case.
  elseif line =~# '^\(case .*\|default\):$'
    let indent -= shiftwidth()

  endif

  return indent
endfun
