" guru.vim: implement the :GoGuru command.
"
" Note: guru is not GOPATH-aware, and there are currently no plans to update it
" (AFAIK).

let s:commands = ['callees', 'callers', 'callstack', 'definition', 'describe',
                \ 'freevars', 'implements', 'peers', 'pointsto', 'referrers',
                \ 'what', 'whicherrs']

fun! gopher#guru#complete(lead, cmdline, cursor) abort
  if gopher#compl#prev_word(a:cmdline, a:cursor) is# '-scope'
    let l:list = gopher#pkg#list_importable()
  else
    let l:list = ['-scope', '-tags', '-reflect']
  endif
  return gopher#compl#filter(a:lead, l:list)
endfun

fun! gopher#guru#do(...) abort
  " Prepend -scope flag unless given in the command.
  " TODO: commands need range: freevars
  let l:flags = a:000
  if index(l:flags, '-scope') is -1
    let l:flags = ['-scope', gopher#bufsetting('gopher_guru_scope', gopher#go#package())] + l:flags
  endif

  " TODO: pass stdin to tool_job: gopher#system#archive()
  call gopher#system#tool_job(function('s:done'), gopher#go#add_build_tags(
        \ ['guru']
        \ + (&modified ? ['-modified'] : [])
        \ + l:flags
        \ + [gopher#buf#cursor(1)]))
endfun

" TODO: errors don't always appear well. Not sure how to best fix that, seems
" more of a Vim issue than anything else :-/
fun! s:done(exit, out) abort
  if a:exit > 0
    " TODO: add hint about scope if appropriate.
    return gopher#error(a:out)
  endif

  call gopher#qf#populate(a:out, '', 'guru')
endfun
