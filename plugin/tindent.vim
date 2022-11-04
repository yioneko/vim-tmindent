if exists("g:loaded_tindent")
  finish
endif

let g:loaded_tindent = v:true

let g:tindent = get(g:, 'tindent', {})
let g:tindent.enabled = get(g:tindent, 'enabled', { -> v:false })
let g:tindent.use_jsregex = get(g:tindent, 'use_jsregex', { -> has("nvim") })

augroup tindent_attach
  autocmd!
  autocmd FileType * call tindent#attach()
augroup END
