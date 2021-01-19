" init.vim: Initialisation of the plugin.

let s:config_done = 0

" Initialize config values.
fun! go#coverage#init#config() abort
  if s:config_done
    return
  endif

  " Set defaults.
  let g:go_coverage_build_tags     = get(g:, 'go_coverage_build_tags', [])
  let g:go_coverage_build_flags    = get(g:, 'go_coverage_build_flags', [])
        \ + (len(g:go_coverage_build_tags) > 0 ? ['-tags', join(g:go_coverage_build_tags, ' ')] : [])

  let s:config_done = 1
endfun
