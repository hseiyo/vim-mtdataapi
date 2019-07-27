if filereadable( expand("%:h") . "/.siteconfig" )
  source %:h/.siteconfig
endif

cnoremap <buffer> w<CR> MtSave<CR>
nnoremap <buffer> <F5> :MtOpen str2nr( expand("%:t") ), 1<CR>
