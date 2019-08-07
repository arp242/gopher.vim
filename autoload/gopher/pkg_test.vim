scriptencoding utf-8
call gopher#init#config()

fun! Test_list_std() abort
  let l:out = gopher#pkg#list_std()

  if len(l:out) < 193
    return Errorf('short len: %d', len(l:out))
  endif
  if l:out[0] isnot# 'archive/tar'
    return Errorf('first package: %s', l:out[0])
  endif
  if l:out[len(l:out)-1] isnot# 'unsafe'
    return Errorf('last package: %s', l:out[len(l:out)-1])
  endif
endfun

fun! Test_list_interfaces() abort
  let l:out = gopher#pkg#list_interfaces('net/http')
  let l:want = ['CloseNotifier', 'CookieJar', 'File', 'FileSystem', 'Flusher',
              \ 'Handler', 'Hijacker', 'Pusher', 'ResponseWriter', 'RoundTripper']

  if l:out != l:want
    return Errorf('%s', l:out)
  endif
endfun
