" Add tags.
function! gopher#tags#add(start, end, count, ...) abort
  let offset = 0
  if a:count is -1
    let l:offset = gopher#internal#cursor_offset()
  endif

  call call('gopher#tags#run', [a:start, a:end, l:offset, 'add', expand('%')] + a:000)
endfunction

" Remove tags.
function! gopher#tags#remove(start, end, count, ...) abort
  let l:offset = 0
  if a:count is -1
    let l:offset = gopher#internal#cursor_offset()
  endif

  call call('gopher#tags#run', [a:start, a:end, l:offset, 'remove', expand('%')] + a:000)
endfunction

" run runs gomodifytag.
function! gopher#tags#run(start, end, offset, mode, fname, ...) abort
  let l:args = {
        \ 'mode':     a:mode,
        \ 'start':    a:start,
        \ 'end':      a:end,
        \ 'offset':   a:offset,
        \ 'fname':    a:fname,
        \ 'cmd_args': a:000}

  if &modified
    let l:args['modified'] = 1
  endif

  let l:result = s:create_cmd(l:args)
  if has_key(result, 'err')
    call gopher#internal#error('s:create_cmd: ' . result.err)
    return -1
  endif

  " TODO: doesn't work on modified buffers when not using visual mode:
  " gopher.vim: line selection is invalid
  " TODO: Doesn't replace correct text when buffer is modified in visual mode.
  " TODO: simplify by allowing a list in tool()
  let l:stdin = join(gopher#internal#lines(), "\n")
  let l:stdin = expand('%') . "\n" . strlen(l:stdin) . "\n" . l:stdin
  let [l:out, l:err] = gopher#system#tool(l:result.cmd, l:stdin)
  if l:err != 0
    call gopher#internal#error(printf('gomodifytags exit %d: %s', l:err, out))
    return
  endif

  call s:write_out(out)
endfunc

" Write output to the buffer.
func s:write_out(out) abort
  " not a json output
  " TODO: This check sucks.
  if a:out[0] !=# '{'
    return
  endif

  " Nothing to do
  if empty(a:out) " || type(a:out) != v:t_string
    return
  endif

  let l:result = json_decode(a:out)
  if type(l:result) isnot v:t_dict
    call gopher#internal#error(printf('gomodifytags unexpected output: %s', a:out))
    return
  endif

  let l:index = 0
  for l:line in range(l:result['start'], l:result['end'])
    call setline(line, l:result['lines'][l:index])
    let l:index += 1
  endfor

  if has_key(l:result, 'errors')
    call gopher#internal#error(printf('errors key: %s', l:result['errors']))
  "  let l:winnr = winnr()
  "  let l:listtype = go#list#Type('GoModifyTags')
  "  call go#list#ParseFormat(l:listtype, '%f:%l:%c:%m', result['errors'], 'gomodifytags')
  "  call go#list#Window(l:listtype, len(result['errors']))

  "  "prevent jumping to quickfix list
  "  exe l:winnr . 'wincmd w'
  endif
endfunc


" create_cmd returns a dict that contains the command to execute gomodifytags
func s:create_cmd(args) abort
  let l:start    = a:args.start
  let l:end      = a:args.end
  let l:offset   = a:args.offset
  let l:mode     = a:args.mode
  let l:cmd_args = a:args.cmd_args
  "TODO: let l:modifytags_transform = go#config#AddtagsTransform()

  let l:cmd = ['gomodifytags']
  call extend(cmd, ['-format', 'json'])
  call extend(cmd, ['-file', a:args.fname])
  "TODO call extend(cmd, ['-transform', l:modifytags_transform])

  if has_key(a:args, 'modified')
    call add(cmd, '-modified')
  endif

  if l:offset != 0
    call extend(cmd, ['-offset', l:offset])
  else
    let range = printf('%d,%d', l:start, l:end)
    call extend(cmd, ['-line', range])
  endif

  if l:mode is# 'add'
    let l:tags = []
    let l:options = []

    if !empty(l:cmd_args)
      for item in l:cmd_args
        let splitted = split(item, ',')

        " tag only
        if len(splitted) == 1
          call add(l:tags, splitted[0])
        endif

        " options only
        if len(splitted) == 2
          call add(l:tags, splitted[0])
          call add(l:options, printf('%s=%s', splitted[0], splitted[1]))
        endif
      endfor
    endif

    " construct options
    if !empty(l:options)
      call extend(cmd, ['-add-options', join(l:options, ',')])
    else
      " default value
      if empty(l:tags)
        " TODO: config
        let l:tags = ['json']
      endif

      " construct tags
      call extend(cmd, ['-add-tags', join(l:tags, ',')])
    endif
  elseif l:mode is# 'remove'
    if empty(l:cmd_args)
      call add(cmd, '-clear-tags')
    else
      let l:tags = []
      let l:options = []
      for item in l:cmd_args
        let splitted = split(item, ',')

        " tag only
        if len(splitted) == 1
          call add(l:tags, splitted[0])
        endif

        " options only
        if len(splitted) == 2
          call add(l:options, printf('%s=%s', splitted[0], splitted[1]))
        endif
      endfor

      " construct tags
      if !empty(l:tags)
        call extend(cmd, ['-remove-tags', join(l:tags, ',')])
      endif

      " construct options
      if !empty(l:options)
        call extend(cmd, ['-remove-options', join(l:options, ',')])
      endif
    endif
  else
    return {'err': printf('unknown mode: %s', l:mode)}
  endif

  return {'cmd': cmd}
endfunc
