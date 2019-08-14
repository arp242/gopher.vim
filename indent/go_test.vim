fun! Test_indent() abort
  for l:f in glob(g:test_packdir .'/indent/testdata/*.go', 0, 1)
    new
    let l:file = readfile(l:f)
    call setline(1, l:file)
    set filetype=go

    normal! G
    let l:ins = fnamemodify(l:f, ':t')[0]
    if l:ins is# '+'
      let l:want = repeat("\t", indent('.') / shiftwidth()) . "\t_"
    elseif l:ins is# '-'
      let l:want = repeat("\t", indent('.') / shiftwidth() - 1) . '_'
    elseif l:ins is# '='
      let l:want = repeat("\t", indent('.') / shiftwidth()) . '_'
    else
      return Errorf('invalid file: %s; first character of filename needs to be +, -, or =')
    end

    exe "normal! o_\<Esc>"

    let l:out = getline('.')
    if l:out !=# l:want
      call Errorf("%s\nout:  %s\nwant: %s", fnamemodify(l:f, ':t'),
            \ s:vt(l:out), s:vt(l:want))
    endif
  endfor
endfun

fun! s:vt(s) abort
  return substitute(a:s, "\t", '\\t', 'g')
endfun
