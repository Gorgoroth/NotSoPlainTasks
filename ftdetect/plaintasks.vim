" ftdetect/plaintasks.vim - NotSoPlainTasks set file type
" Language: PlainTasks
" Author: Valentin Klinghammer <hacking.quelltextfabrik.de>
" Original: David Elentok
" Version: 1.0
" License: Same as Vim itself, see :help license

augroup NotSoPlainTasks
  autocmd BufNewFile,BufReadPost *.TODO set filetype=plaintasks
  autocmd BufNewFile,BufReadPost *.todo set filetype=plaintasks
augroup END
