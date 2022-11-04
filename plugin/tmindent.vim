if exists("g:loaded_tmindent")
  finish
endif

let g:loaded_tmindent = v:true

let g:tmindent = get(g:, 'tmindent', {})
let g:tmindent.enabled = get(g:tmindent, 'enabled', { -> v:false })
let g:tmindent.use_jsregex = get(g:tmindent, 'use_jsregex', { -> has("nvim") })

augroup tmindent_attach
  autocmd!
  autocmd FileType * call tmindent#attach()
augroup END
