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
  let line_number = matchstr(a:buffer_line, '\d*:')
  let line_comment_temp = split(line, ': ')
  let line_comment = line_comment_temp[1]

  " Loop through project_file
  let file_line_ctr = a:start
  while file_line_ctr <= a:finish
    " Setup current project file line variables
    let file_todo_item = get(a:project_file, file_line_ctr)
    " let file_line = matchstr(file_todo_item, '\d*:.*')
    let file_line_number = match(file_todo_item, '\d*:')
    let file_line_comment_temp = split(file_todo_item, ': ')
    let file_line_comment = line_comment_temp[1]

    " --- first handle matching line numbers
    let line_number_match = match(line_number, file_line_number)
    if(line_number_match != -1)
      call add(a:return_list, a:buffer_line)
      call remove(a:project_file, file_line_ctr)
      " Matching comment found, return successful
      return 1
    endif

    " --- Second handle matching comments
    let line_comment_match = match(line_comment, file_line_comment)
    if(line_comment_match != -1)
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
" ----------------------------------------------------------------------------
function! CleanProjectFile(project_file, start, finish)
  echom 'CleanProjectFile()'
  " All matches have already been removed
  " So we can safely remove all lines that don't fit our criteria
  " TODO remove debug echos
  echom 'Remove between '.(a:start).' and '.(a:finish)

  let finish = a:finish
  let remove_lines = a:start
  while remove_lines < finish
    let item_to_remove = get(a:project_file, remove_lines)
    " TODO don't remove tasks without linenumbers
    " TODO don't remove completed tasks
    " TODO don't remove cancelled tasks
    echom "Remove item in line ".remove_lines." content: ".item_to_remove
    call remove(a:project_file, remove_lines)
    " let remove_lines += 1
    let finish -= 1
  endwhile

endfunction

" ----------------------------------------------------------------------------
" --- Handles adding of new tasks
" ----------------------------------------------------------------------------
function! AddNewTodo()

endfunction

" ----------------------------------------------------------------------------
" --- Handles buffer and project file comparison
" ----------------------------------------------------------------------------
function! CompareTodos(project_file, start, finish, buffer_todo)
  echom 'CompareTodos()'
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

" --- Add all todo from comments to project.todo in working folder root
function! SaveTodo(lines)
  echom 'SaveTodo()'
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

" filename.ext: and then list all todos
function! SearchForTodos()
  let blacklist_match = match(bufname('%'), '.*\.todo')
  if(blacklist_match == -1)
    " First look for todos in current buffer
    let lines = []
    let i = 0
    while i <= line('$')
      let line = getline(i)
      let match = matchstr(line, 'TODO .*\C')
      if(!empty(match))
        let exact_match = split(match, 'TODO ')[0]
        let templine = '☐ '.i.': '.exact_match
        call add(lines, templine)
      endif
      let i += 1
    endw
    " Handle todos for current buffer
    " TODO skip this test if we found no todos
    call SaveTodo(lines)
  endif
endfunction
