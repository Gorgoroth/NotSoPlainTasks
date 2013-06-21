" TODO have file comment header

augroup NotSoPlainTasks
  autocmd BufWritePost * call NotSoPlainTasksHandleBuffer()
  autocmd FileType plaintasks setlocal foldmethod=marker
  autocmd FileType plaintasks setlocal foldclose=all
augroup END

" ----------------------------------------------------------------------------
" --- This is our main loop that ties the plugin together
" ----------------------------------------------------------------------------
function NotSoPlainTasksHandleBuffer()
  let relevant_block = []
  let user_tasks = []
  let open_tasks = []
  let done_tasks = []
  let cancelled_tasks = []

  let current_todos = GetCurrentTodosFromBuffer()
  if(current_todos == [])
    return
  endif
  let start = CutOrCreateRelevantTodoBlock(relevant_block, bufname('%'))

  if(relevant_block != [])
    let open_tasks = GetLinesFromBlock(relevant_block, 'open_tasks')
    let user_tasks = GetLinesFromBlock(relevant_block, 'user_tasks')
    let done_tasks = GetLinesFromBlock(relevant_block, 'done_tasks')
    let cancelled_tasks = GetLinesFromBlock(relevant_block, 'cancelled_tasks')
  endif

  " Handle creation and marking of tasks
  call HandleTaskManagement(current_todos, open_tasks, done_tasks)

  " Write tasks to file in our format
  call WriteTasksToFile(start, user_tasks, open_tasks, done_tasks, cancelled_tasks)
endfunction

" ----------------------------------------------------------------------------
" --- Searches buffer for todos and returns a list of them
" ----------------------------------------------------------------------------
function GetCurrentTodosFromBuffer()
  let lines = []

  " Skip files in our blacklist
  if(bufname('%') !~ '.*\.todo')
    let i = 0
    while i <= line('$')
      let line = getline(i)
      " We want to use this plugin for this file, so we need to skip the
      " regexes a few lines below this
      if(line =~# 'TODO \.\*')
        let i += 1
        continue
      endif
      " Try to weed out unwanted triggers, keyword must follow comment
      " characters immediately
      if( (line =~# '" TODO .*') || (line =~# '// TODO .*') || (line =~# '# TODO .*') || (line =~# '/* TODO .*') )
        let exact_match = split(line, 'TODO ')[1]
        " Assemble new task
        let templine = '☐ '.i.': '.exact_match
        call add(lines, templine)
      endif
      let i += 1
    endw
  endif
  return lines
endfunction

" ----------------------------------------------------------------------------
" --- Cut out the relevant block and leave just header and newline
" --- or create header and new line
" --- Returns pointer to start for safe writing
" --- Also, cut out really means delete
" ----------------------------------------------------------------------------
function CutOrCreateRelevantTodoBlock(relevant_block, current_filename)
  let header = 'FILE '.a:current_filename.':'
  let footer = ''
  let found_something = 0

  let todo_filename = getcwd().'/project.todo'
  let todo_file = []
  let start = 1

  " If project todo file already exists, read it
  let file_exists = findfile(todo_filename)
  if(file_exists != '')
    let todo_file = readfile(todo_filename)

    " Get region for current filename
    let start = match(todo_file, header)
    if(start != -1)
      let found_something = 1
      " We do not want to manipulate the todo group header
      let start += 1
      " If there is already an entry, check for existing todos
      let finish = match(todo_file, 'FILE .*:\C', start)
      " If there is no file group todo list after ours then its EOF
      if(finish == -1)
        let finish = len(todo_file)
      endif
      " Since we match the occurence of FILE, the block ends on line prior
      let finish -= 1

      " Copy the relevant part
      let index = start
      while index < finish
        let line = get(todo_file, index)
        call add(a:relevant_block, line)
        let index += 1
      endwhile
      " And remove it
      call remove(todo_file, start, finish)
    endif
  endif

  " In case we didn't find the file or block, create it
  if(found_something == 0)
    call add(todo_file, header)
    call add(todo_file, footer)
  endif

  " Write changes to file
  call writefile(todo_file, todo_filename)

  return start
endfunction

" ----------------------------------------------------------------------------
" --- Searches project file and returns a list of matching lines
" ----------------------------------------------------------------------------
function GetLinesFromBlock(file_block, type)
  let matching_lines = []
  let mark = ''
  let not_mark = ''

  if(a:type =~ 'user_tasks')
    let mark = '☐ .*'
    let not_mark = '☐ \d*:.*'
  elseif(a:type =~ 'open_tasks')
    let mark = '☐ \d*:.*'
  elseif(a:type =~ 'done_tasks')
    let mark = '✔.*'
  elseif(a:type =~ 'cancelled_tasks')
    let mark = '✘.*'
  else
    " Not a valid option
    return []
  endif

  " Because we manipulate the array we iterate over this is a bit tricky.
  " If we do not find an item we increment the index
  " If we find and delete a line, we keep the line index but decrement the upper bound
  " That is because we stay in the same line and the next ones move up if we
  " delete a list item
  let finish = len(a:file_block)
  let index = 0
  while index < finish
    let current_line = get(a:file_block, index)
    " if((current_line =~ mark) && (current_line !~ not_mark))
    if((current_line =~ mark))
      call add(matching_lines, current_line)
      call remove(a:file_block, index)
      let finish -= 1
      continue
    endif
    let index += 1
  endwhile

  return matching_lines
endfunction

" ----------------------------------------------------------------------------
" --- Loops through the current task in the buffer and either moves them to
" --- the open or done tasks
" ----------------------------------------------------------------------------
function HandleTaskManagement(current_todos, open_tasks, done_tasks)
  " Delete all open_tasks that have matches in current buffer
  " Buffer is more recent and therefore more relevant
  let i = 0
  while i < len(a:current_todos)
    " TODO see, if we can make the filter smarter
    let line = a:current_todos[i]
    let tmp = split(line, ': ')
    let line = tmp[1]
    call filter(a:open_tasks, 'v:val !~ "'.line.'"')
    let i += 1
  endwhile

  " Mark all open_tasks as done, that are not in buffer
  " All tasks that are still open are now in current_todos
  " all left in open_tasks are done
  let done = len(a:open_tasks)
  let i = 0
  while i < done
    " That means add to done_tasks
    let temp = substitute(a:open_tasks[i], '☐', '✔', '')
    call insert(a:done_tasks, temp." @done (" . strftime("%Y-%m-%d %H:%M") .")", 0)
    " Remove from open_tasks
    call remove(a:open_tasks, i)
    let done -= 1
  endwhile

  " Add all tasks from buffer to open tasks
  let i = 0
  while i < len(a:current_todos)
    call add(a:open_tasks, a:current_todos[i])
    let i += 1
  endwhile
endfunction

" ----------------------------------------------------------------------------
" --- Writes tasks to file
" --- Requirement: projects.todo must have been created, start must point to
" --- one line after file todo group header
" ----------------------------------------------------------------------------
function WriteTasksToFile(start, user_tasks, open_tasks, done_tasks, cancelled_tasks)
  let todo_filename = getcwd().'/project.todo'
  let todo_file = readfile(todo_filename)
  let index = a:start

  " --- Add user tasks after file group todo header
  if(!empty(a:user_tasks))
    call extend(todo_file, a:user_tasks, index)
    let index += len(a:user_tasks)
  endif

  " --- Add open tasks in order of appearance in source code
  if(!empty(a:open_tasks))
    call extend(todo_file, a:open_tasks, index)
    let index += len(a:open_tasks)
  endif

  " --- Add, find or remove fold start marker if necessary
  if(!empty(a:done_tasks) || !empty(a:cancelled_tasks))
    call insert(todo_file, '{{{', index)
    let index += 1
  endif

  " --- Add done tasks if any
  if(!empty(a:done_tasks))
    call extend(todo_file, a:done_tasks, index)
    let index += len(a:done_tasks)
  endif

  " --- Add cancelled tasks if any
  if(!empty(a:cancelled_tasks))
    call extend(todo_file, a:cancelled_tasks, index)
    let index += len(a:cancelled_tasks)
  endif

  " --- Add, find or remove fold end marker if necessary
  if(!empty(a:done_tasks) || !empty(a:cancelled_tasks))
    call insert(todo_file, '}}}', index)
    let index += 1
  endif

  " --- Add newline
  call insert(todo_file, '', index)
  let index += 1

  " --- Write to file
  call writefile(todo_file, todo_filename)
endfunction

