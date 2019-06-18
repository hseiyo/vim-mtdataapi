if filereadable( expand("%:h") . "/.siteconfig" )
  source %:h/.siteconfig
endif

cnoremap <buffer> w<CR> :call mtdataapi#saveEntry()<CR>
