" Vim global plugin for Movable Type
" File:         mtdataapi.vim
" Author:	Seiyo Hiramatsu <hseiyo@gmail.com>
" License:	MIT License

let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_mtdataapi')
 finish
endif
let g:loaded_mtdataapi = 1
if !exists(":MtGet")
  command! -nargs=1 MtGet call mtdataapi#getEntry(<args>)
endif
if !exists(":MtCreate")
  command! -nargs=0 MtCreate call mtdataapi#createEntry()
endif
if !exists(":MtEdit")
command! -nargs=0 MtEdit call mtdataapi#editEntry()
endif

let &cpoptions = s:save_cpo
unlet s:save_cpo
