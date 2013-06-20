" TODO have file comment header
" TODO have comment headers for each function

augroup NotSoPlainTasks
  autocmd BufWritePost * call SearchForTodos()
augroup END

" ----------------------------------------------------------------------------
" --- Check in project file todo block for matches with buffer_line
" ---
" Returns 1 if a match is found and a line from the project has been removed
" Returns 0 if no match has been found
" ----------------------------------------------------------------------------
function! CheckForTodoMatches(project_file, start, finish, buffer_line, return_list)

  " Setup our variables for analyzing
  let line = matchstr(a:buffer_line, '\d*:.*')
  let line_number = matchstr(a:buffer_line, '\☐ d*:')
  let line_comment_temp = split(line, ': ')
  let line_comment = line_comment_temp[1]

  " Loop through project_file
  let file_line_ctr = a:start
  while file_line_ctr < a:finish
    " Setup current project file line variables
    let file_todo_item = get(a:project_file, file_line_ctr)
    if(file_todo_item !~ '☐ ')
      " If file line does not contain an open task, skip
      let file_line_ctr += 1
      continue
    endif
    let file_line_number = matchstr(file_todo_item, '☐ \d*:')
    let file_line_comment_temp = split(file_todo_item, ': ')
    let file_line_comment = file_line_comment_temp[1]

    " --- first handle matching line numbers
    if(line_number =~ file_line_number)
      call add(a:return_list, a:buffer_line)
      call remove(a:project_file, file_line_ctr)
      " Matching comment found, return successful
      return 1
    endif

    " --- Second handle matching comments
    if(line_comment =~ file_line_comment)
      " Line number most likely does not match, so update from buffer
      call add(a:return_list, a:buffer_line)
      call remove(a:project_file, file_line_ctr)
      " Matching comment found, return successful
      return 1
    endif

    " Nothing found yet, keep looking
    let file_line_ctr += 1
  endwhile

  " No matching comment found, return unsuccessful
  return 0
endfunction

" ----------------------------------------------------------------------------
" --- Handles removing and marking tasks as done
" TODO explain better what CleanProjectFile() does
" ----------------------------------------------------------------------------
function! CleanProjectFile(project_file, start, finish)
  " All matches have already been removed
  " So we can safely remove all lines that don't fit our criteria

  echom 'Currently still in file: '
  let i = a:start
  while i < a:finish
    let item = get(a:project_file, i)
    echom ' * '.item
    let i += 1
  endwhile

  " Because we manipulate the array we iterate over this is a bit tricky.
  " If we change an item we increment the line_index
  " If we delete a line, we keep the line index but decrement the upper bound
  " That is because we stay in the same line and the next ones move up if we
  " delete a list item
  let finish = a:finish
  let line_index = a:start
  while line_index <= finish
    let item_to_remove = get(a:project_file, line_index)

    if(item_to_remove =~ '☐ \d*:.*')
      " Task has been removed from source, so mark as done
      let a:project_file[line_index] = substitute(a:project_file[line_index], '☐', '✔', '')
      let a:project_file[line_index] .= " @done (" . strftime("%Y-%m-%d %H:%M") .")"
      let line_index += 1
    elseif(item_to_remove =~ '☐ .*')
      " Task has no line number and was most likely added by user
      " do nothing
      " TODO don't remove tasks without linenumbers
      let line_index += 1
    elseif(item_to_remove =~ '✔.*')
      " Task was previously marked as done
      " do nothing
      let line_index += 1
    elseif(item_to_remove =~ '✘.*')
      " Task was cancelled by user
      " do nothing
      let line_index += 1
    else
      " Line does not fit our criteria, remove
      call remove(a:project_file, line_index)
      let finish -= 1
    endif
  endwhile

  " Add new line at the end for structure
  call insert(a:project_file, '', finish+1)

endfunction


" ----------------------------------------------------------------------------
" --- Handles buffer and project file comparison
" TODO explain better what CompareTodos() function does
" ----------------------------------------------------------------------------
function! CompareTodos(project_file, start, finish, buffer_todo)
  let return_list = []
  let removed_file_lines_ctr = 0
  let finish = a:finish

  " so loop through buffer_todo
  let buf_line_ctr = 0
  while buf_line_ctr < len(a:buffer_todo)
    " Get current buffer item
    let buffer_todo_item = get(a:buffer_todo, buf_line_ctr)
    " Keep track of if we have found a match in the project todo
    " for the current buffer item
    let found_match = 0

    " --- Check if the current buffer line has a match in the project file
    let found_match = CheckForTodoMatches(a:project_file, a:start, finish, buffer_todo_item, return_list)
    let removed_file_lines_ctr += found_match
    " Since we remove entries in CheckForTodoMatches, we need to keep the
    " bound up to date
    let finish -= found_match

    " --- If no match is found, add as new todo
    if(found_match == 0)
      call add(return_list, buffer_todo_item)
    endif

    let buf_line_ctr += 1
  endwhile

  " --- Handle tasks that have no match in the current buffer
  call CleanProjectFile(a:project_file, a:start, finish)

  return return_list
endfunction

" ----------------------------------------------------------------------------
" --- Add all todo from comments to project.todo in working folder root
" --- Takes list of todos from buffer as parameter
" --- Then searches in project.todo if current buffer has an entry
" --- if yes, CompareTodos is called, which handles marking
" --- if not, entry is created and the buffer todos added to the file todos
" --- it then saves the changes to the project.todo
" ----------------------------------------------------------------------------
function! SaveTodo(lines)
  let filename = bufname('%')
  let todo_filename = getcwd().'/project.todo'
  let todo_file = []

  " If project todo file already exists, read it
  let file_exists = findfile(todo_filename)
  if(file_exists != '')
    let todo_file = readfile(todo_filename)
  endif

  " Get region for current filename
  let start = match(todo_file, 'FILE '.filename.':')
  if(start != -1)
    " We do not want to manipulate the todo group header
    let start += 1
    " If there is already an entry, check for existing todos
    let finish = match(todo_file, 'FILE .*:', start)
    " If there is no file group todo list after ours then its EOF
    if(finish == -1)
      let finish = len(todo_file)
    endif
    " Since we match the occurence of FILE, the block ends on line prior
    let finish -= 1

    " Handle comparing todos from buffer and source code
    let write_file = CompareTodos(todo_file, start, finish, a:lines)
    call extend(todo_file, write_file, start)
  else
    " Insert new block at end of file
    call insert(a:lines, 'FILE '.filename.':', 0)
    call add(a:lines, '')
    call extend(todo_file, a:lines)
  endif

  call writefile(todo_file, todo_filename)
endfunction

" ----------------------------------------------------------------------------
" --- Searches buffer for todosand puts them in a list
" then calls SaveTodo with the list as parameter
" ----------------------------------------------------------------------------
function! SearchForTodos()
  let blacklist_match = match(bufname('%'), '.*\.todo')
  if(blacklist_match == -1)
    " First look for todos in current buffer
    let lines = []
    let i = 0
    while i <= line('$')
      let line = getline(i)
      let match = matchstr(line, 'TODO .*\C')

      " We need to skip the next line so we can use todo for this exact file
      if(line =~# 'TODO \.\*')
        let i += 1
        continue
      endif
      if( (line =~# '" TODO .*') || (line =~# '// TODO .*') || (line =~# '# TODO .*') || (line =~# '/* TODO .*') )
        let exact_match = split(match, 'TODO ')[0]
        let templine = '☐ '.i.': '.exact_match
        call add(lines, templine)
      endif
      let i += 1
    endw
    " Handle todos for current buffer
    if(lines != [])
      call SaveTodo(lines)
    endif
  endif
endfunction
