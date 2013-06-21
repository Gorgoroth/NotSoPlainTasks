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
nnoremap gf :call JumpToFileAndLine()<cr>
nnoremap <Leader>nptj :call JumpToFileAndLine()<cr>
" Done with task in project.todo
nnoremap <Leader>nptd :call ToggleComplete()<cr>

function! JumpToFileAndLine()
  let line = getline('.')
  let line_number = matchstr(line, '\(☐ \)\@<=\(\d*\)\(.*\)\@<=')

  let file_name_regex = '\(^FILE \)\@<=\(.*\)\(:\)\@<='
  let file_name_number = search(file_name_regex, 'bnW')
  let file_name_line = getline(file_name_number)
  let filename = matchstr(file_name_line, file_name_regex)
  let filename = substitute(filename, ':', '','')

  echom "Jumping to ".filename.':'.line_number

  if(filename != '')
    exec ':e '.filename
    if(line_number != '')
      exec 'normal '.line_number.'G'
    else
      exec 'normal gg'
      echom 'Linenumber not found in file'
    endif
  else
    echom 'File not found'
  endif
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
