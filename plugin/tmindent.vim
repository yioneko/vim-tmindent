if exists("g:loaded_tmindent")
  finish
endif

let g:loaded_tmindent = v:true

let g:tmindent = get(g:, 'tmindent', {})
let g:tmindent.enabled = get(g:tmindent, 'enabled', { -> v:false })
let g:tmindent.use_treesitter = get(g:tmindent, 'use_treesitter', { -> has('nvim') })

function s:is_enabled() abort
  if has("nvim")
    return luaeval("require('tmindent').is_enabled()")
  endif
  return g:tmindent.enabled()
endfunction

function tmindent#attach() abort
  if s:is_enabled()
    setlocal indentexpr=tmindent#indentexpr()
  endif
endfunction

augroup tmindent
  autocmd!
  autocmd FileType * call tmindent#attach()
augroup END
