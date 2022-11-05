if exists("g:loaded_tmindent")
  finish
endif

let g:loaded_tmindent = v:true

let g:tmindent = get(g:, 'tmindent', {})
let g:tmindent.enabled = get(g:tmindent, 'enabled', { -> v:false })

augroup tmindent_attach
  autocmd!
  autocmd FileType * call tmindent#attach()
augroup END
