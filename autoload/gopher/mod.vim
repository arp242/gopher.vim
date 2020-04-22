" mod.vim: Utilities for working with go.mod files.

" Add or remove replace directives.
fun! gopher#mod#replace(...)
  " TODO: get arguments.
  let l:mod = ''
  let l:path = ''

  if l:mod is# ''
    " TODO: be a bit smarter in go.mod file, since now 'require' is considered a
    " module as well.
    let l:mod = expand('<cWORD>')
  endif

  if &filetype is# 'go'
    let l:gomod = gopher#go#gomod()
    if l:gomod is# ''
      return gopher#error('No go.mod file found.')
    endif

    if l:mod is# ''
      " On identifier: fmt.Printf("..")
      if l:mod =~# '\.'
        let l:mod = split(l:mod, '.')[0]
        let l:resolve = gopher#pkg#resolve()
        if l:resolve is# ''
          return gopher#error('Unknown package: %s', l:mod)
        endif

        let l:mod = l:resolve
      " On package: "fmt".
      else
        let l:mod = trim(l:mod, '"')
      endif
    endif
  endif

  if l:mod is# ''
    return gopher#error('Not a package: %s', l:mod)
  endif

  if l:path is# ''
    let l:path = '../' . fnamemodify(l:mod, ':t')
  endif

  let l:line = printf('replace %s => %s', l:mod, l:path)

  " TODO: :GoModReplace on something that already exists should remove it.
  " TODO: Don't add duplicate replaces.

  " Place before first require or replace.
  for l:i in range(1, line('$'))
    if getline(l:i) =~# '\v^(require|replace)'
      call append(l:i-1, [l:line, ''])
      return
    endif
  endfor

  " Nothing in the file yet.
  call append('$', l:line)
endfun
