augroup NotSoPlainTasks
  autocmd BufWritePost * call SearchForTodos()
augroup END

function! CompareTodos(project_file_todo, start, finish, buffer_todo)

  " Source code file is authorative
  " Except for cancelled and done tasks, as well as tasks without line numbers

  " Cases
  "   1. User adds new todo in source code
  "   2. User removes todo in source code
  "   3. User changes todo text
  "   4. User changes source code so todo line number changes
  "   5. changes source code and todo tex
  "   6. User marks task as done in project todo
  "   7. User creates new tasks in project todo
  "
  " Case 1: Create new todo
  " Case 2: Remove todo/mark as done
  " Case 3: like below
  " Case 4: Try to find matching todo and update
  " Case 5: Create new todo, then clean up orphaned todos without matches
  " Case 6: Remove todo line in source code
  " Case 7: Do nothing if there is no line number, simply keep at position

  " TODO figure out how to distinguish between completed and changed todos
  " For now lets simply mark all removed tasks as done
  " and create new tasks for those that have no clear matches

  " let return_list = deepcopy(a:project_file_todo)
  let return_list = []
  let file_lines_that_have_match = []

  " so loop through buffer_todo
  let buf_line_ctr = 0
  while buf_line_ctr < len(a:buffer_todo)
    " Get current buffer item
    let buffer_todo_item = get(a:buffer_todo, buf_line_ctr)
    let found_match = 0

    " Setup our variables for analyzing
    let line = matchstr(buffer_todo_item, '\d*:.*')
    let line_number = matchstr(buffer_todo_item, '\d*:')
    let line_comment_temp = split(line, ': ')
    let line_comment = line_comment_temp[1]
    " echom line
    " echom line_number
    " echom line_comment

    " Loop through project_file_todo
    let file_line_ctr = a:start+1
    while file_line_ctr < a:finish-1
      " Get current file item
      let file_todo_item = get(a:project_file_todo, file_line_ctr)

      " Setup current line variables
      let fileline = matchstr(buffer_todo_item, '\d*:.*')
      let file_line_number = match(file_todo_item, '\d*:')
      let file_line_comment_temp = split(line, ': ')
      let file_line_comment = line_comment_temp[1]

      " --- first handle matching line numbers
      let line_number_match = match(line_number, file_line_number)
      if(line_number_match != -1)
        " Line number found, check if text has changed
        let exact_match = match(buffer_todo_item, file_todo_item)
        if(exact_match == -1)
          " Comment has changed, use from buffer
          call add(return_list, buffer_todo_item)
          call remove(a:project_file_todo, file_line_ctr)
        else
          " Do nothing, we will use from project_file
        endif
        " line number found, we're done with this buffer line, break out of loop
        let found_match = 1
        break
      endif

      " --- Second handle matching comments
      let line_comment_match = match(line_comment, file_line_comment)
      if(line_comment_match != -1)
        " Line number most likely does not match, so update from buffer
        call add(return_list, buffer_todo_item)
        call remove(a:project_file_todo, file_line_ctr)

        " comment found, we're done with this buffer line, break out of loop
        let found_match = 1
        break
      endif

      let file_line_ctr += 1
    endwhile

    " --- Third add new todos
    if(found_match == 0)
      call add(return_list, buffer_todo_item)
    endif

    " --- TODO Fourth remove all comments with no matches

    let buf_line_ctr += 1
  endwhile

  " call remove(a:project_file_todo, a:start+1, a:finish-2)
  return return_list
endfunction

" --- Add all todo from comments to project.todo in working folder root
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
    " If there is already an entry, check for existing todos
    let finish = match(todo_file, 'FILE .*', start+1)
    " If there is no file group todo list after ours then its EOF
    if(finish == -1)
      let finish = len(todo_file)
    endif

    " Handle comparing todos from buffer and source code
    let write_file = CompareTodos(todo_file, start, finish, a:lines)
    call extend(todo_file, write_file, start+1)
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
  " TODO don't do this for todo list specific files, e.g. *.todo
  if(bufname('%') != 'project.todo')
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
    call SaveTodo(lines)
  endif
endfunction
