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

" TODO think of better keyboard shortcuts
nnoremap <buffer> + :call NewTask()<cr>A
nnoremap <buffer> = :call ToggleComplete()<cr>

" TODO this is also mapped to Enter, why?
nnoremap <buffer> <C-M> :call ToggleCancel()<cr>
" TODO separator doesn't work
abbr -- <c-r>=Separator()<cr>

" when pressing enter within a task it creates another task
" TODO checkout why this doesnt work
setlocal comments+=n:☐

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

function! ToggleCancel()
  let line = getline('.')
  if line =~ "^ *✘"
    s/^\( *\)✘/\1☐/
    s/ *@cancelled.*$//
  elseif line =~ "^ *☐"
    s/^\( *\)☐/\1✘/
    let text = " @cancelled (" . strftime("%Y-%m-%d %H:%M") .")"
    exec "normal A" . text
    normal _
  endif
endfunc

" TODO What is A and I?
function! NewTask()
  let line=getline('.')
  if line =~ "^ *$"
    normal A☐
  else
    normal I☐
  end
endfunc

function! Separator()
    let line = getline('.')
    if line =~ "^-*$"
      return "--- ✄ -----------------------"
    else
      return "--"
    end
endfunc
