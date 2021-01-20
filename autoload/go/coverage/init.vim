" init.vim: Initialisation of the plugin.

let s:config_done = 0

" Initialize config values.
fun! go#coverage#init#config() abort
  if s:config_done
    return
  endif

  " Set defaults.
  let g:go_coverage_highlight      = get(g:, 'go_coverage_highlight', ['string-spell', 'string-fmt'])
  let g:go_coverage_tag_transform  = get(g:, 'go_coverage_tag_transform', 'snakecase')
  let g:go_coverage_tag_default    = get(g:, 'go_coverage_tag_default', 'json')
  let g:go_coverage_tag_complete   = get(g:, 'go_coverage_tag_complete', ['db', 'json', 'json,omitempty', 'yaml'])

  let s:config_done = 1
endfun
