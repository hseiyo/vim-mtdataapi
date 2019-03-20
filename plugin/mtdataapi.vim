if exists('g:loaded_mt_dataapi')
 finish
endif
let g:loaded_mt_dataapi = 1
command! -nargs=1 MtGet call mtdataapi#get(<args>)
command! -nargs=0 MtCreate call mtdataapi#createEntry()
command! -nargs=0 MtEdit call mtdataapi#editEntry()
