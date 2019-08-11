scriptencoding utf-8
call gopher#init#config()

fun! Test_list_interfaces() abort
  let l:out = gopher#pkg#list_interfaces('net/http')
  let l:want = ['CloseNotifier', 'CookieJar', 'File', 'FileSystem', 'Flusher',
              \ 'Handler', 'Hijacker', 'Pusher', 'ResponseWriter', 'RoundTripper']

  if l:out != l:want
    return Errorf('%s', l:out)
  endif
endfun
