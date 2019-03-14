" tags.vim: Implement :GoTags.
"
" TODO: :GoTags json=foo doesn't give the expected results?

" Modify tags.
fun! gopher#tags#modify(start, end, count, ...) abort
  let l:commands = {'add': [], 'rm': []}
  let l:rm = 0
  for l:arg in a:000
    if l:rm
      let l:rm = 0
      call add(l:commands.rm, l:arg)
    elseif l:arg is# '-rm'
      let l:rm = 1
    else
      call add(l:commands.add, l:arg)
    endif
  endfor

  " Add default tag, unless just -rm is given.
  if len(l:commands.add) + len(l:commands.rm) is 0 && !l:rm
    call add(l:commands.add, g:gopher_tag_default)
  endif

  let l:offset = (a:count > -1 ? 0 : gopher#buf#cursor())
  if len(l:commands.add) > 0
    call s:run(a:start, a:end, l:offset, 'add', l:commands.add)
  endif
  if len(l:commands.rm) > 0 || l:rm
    call s:run(a:start, a:end, l:offset, 'remove', l:commands.rm)
  endif
endfun

fun! s:run(start, end, offset, mode, tags) abort
  let [l:out, l:err] = gopher#system#tool(
        \ s:create_cmd(a:mode, a:start, a:end, a:offset, a:tags),
        \ gopher#system#archive())
  if l:err
    return gopher#error('gomodifytags exit %d: %s', l:err, l:out)
  endif

  let l:outlist = split(l:out, "\n")
  call setline(1, l:outlist)
  if line('$') - 1 > len(l:outlist)
    exe printf('%d,%dd', len(l:outlist), line('$') - 1)
    undojoin
  endif

  " call s:write_out(l:out)
endfun

" Create the command to run gomodifytags.
"
" mode          add or rm
" start, end    Run for this line range.
" offset        Run for the field at the given byte offset.
" tags          List of tags (e.g. ['json'], ['json,flag'], ['json', 'db'])
fun! s:create_cmd(mode, start, end, offset, tags) abort
  " Operating on modified buffers may not work or give the wrong output when
  " using -format json, so just replace the entire buffer until this is fixed.
  " https://github.com/fatih/gomodifytags/issues/39
  let l:cmd = ['gomodifytags',
        \ '-format', 'source',
        \ '-file', expand('%')]
        \ + (g:gopher_tag_transform isnot# '' ? ['-transform', g:gopher_tag_transform] : [])
        \ + (&modified ? ['-modified'] : [])
        \ + (a:offset isnot 0 ? ['-offset', a:offset] : ['-line', printf('%d,%d', a:start, a:end)])

  " Create list if just tag names, without options.
  let l:tags = map(copy(a:tags), {i, v -> split(l:v, ',')[0] })

  " Special case: remove all tags (:GoTags -rm).
  if a:mode is# 'remove' && len(l:tags) is 0
    return l:cmd + ['-clear-tags']
  endif

  " json,foo -> json=foo
  let l:opts = filter(
        \ map(a:tags, {i, v -> len(split(l:v, ',')) is 2 ? substitute(l:v, ',', '=', '') : ''}),
        \ {i, v -> v isnot# ''})

  return l:cmd
        \ + [printf('-%s-tags', a:mode), join(l:tags, ',')]
        \ + (!empty(l:opts) ? [printf('-%s-options', a:mode), join(l:opts, ',')] : [])
endfun

" Write output to the buffer.
" fun! s:write_out(out) abort
"   try
"     let l:result = json_decode(a:out)
"   catch
"     return gopher#error(a:out)
"   endtry
"   if type(l:result) isnot v:t_dict
"     return gopher#error('unexpected output: %s', a:out)
"   endif
"
"   let l:index = 0
"   for l:line in range(l:result['start'], l:result['end'])
"     call setline(l:line, l:result['lines'][l:index])
"     let l:index += 1
"   endfor
"
"   if has_key(l:result, 'errors')
"     call gopher#error(l:result['errors'])
"   endif
" endfun
