" ftplugin/plaintasks.vim - Vim filetype plugin for PlainTasks
" Language: PlainTasks
" Author: Valentin Klinghammer <hacking.quelltextfabrik.de>
" Original: David Elentok
" Version: 1.0
" License: Same as Vim itself, see :help license

" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
  finish
endif

" Default keyboard bindings in project.todo
" <Leader>nptc " clean done and cancelled tasks from project.todo
" New task in project.todo
nnoremap <Leader>nptn :call NewTask()<cr>A
" <Leader>nptj " Jump to source code
nnoremap <Leader>nptj :call JumpToFileAndLine()<cr>
" Done with task in project.todo
nnoremap <Leader>nptd :call ToggleComplete()<cr>

" TODO think of better keyboard shortcuts
nnoremap <buffer> =

" when pressing enter within a task it creates another task
" TODO checkout why this doesnt work
setlocal comments+=n:☐

function! JumpToFileAndLine()
  let line = getline('.')
  " Extract filename
  let filename = ''
  " TODO extract line number
  let line_number = matchstr(line, '^\%(☐ \)\d*\%(:\)')
  echom "Jumping to ".filename.':'.line_number
  "
  " TODO check if file exists
    " TODO if yes check if line number exists in file
    "   TODO if yes, jump to file and line
    "   TODO if not, jump to file, display message that line wasn't found
    " TODO if not, display message that file wasn't found
endfunction

function! ToggleComplete()
  let line = getline('.')
  if line =~ "^ *✔"
    s/^\( *\)✔/\1☐/
    s/ *@done.*$//
  elseif line =~ "^ *☐"
    s/^\( *\)☐/\1✔/
    " TODO have an option for the date format
    let text = " @done (" . strftime("%Y-%m-%d %H:%M") .")"
    exec "normal A" . text
    normal _
  endif
endfunc

function! NewTask()
  let line=getline('.')
  if line =~ "^ *$"
    normal A☐
  else
    normal o☐
  end
endfunc
