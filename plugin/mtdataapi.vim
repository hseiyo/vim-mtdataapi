if exists('g:loaded_mt_dataapi')
 finish
endif
let g:loaded_mt_dataapi = 1
command! -nargs=1 MtGet call mtdataapi#get(<args>)
