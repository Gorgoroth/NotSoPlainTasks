augroup NotSoPlainTasks
  autocmd BufWritePost * call SearchForTodos()
augroup END

" --- Add all todo from comments to project.todo in working folder root
function! SaveTodo(lines)
  let filename = bufname('%')
  let todo_filename = getcwd().'/project.todo'
  let todo_file = []

  let file_exists = findfile(todo_filename)
  if(file_exists != 0)
    let todo_file = readfile(todo_filename)
  endif

  " TODO how does this work when file is not yet present
  " TODO adding a test

  " Get region for current filename
  let start = match(todo_file, 'FILE '.filename.':')
  if(start != -1)
    " If there is already an entry, check for existing
    let finish = match(todo_file, 'FILE .*', start+1)

    " TODO check if this is working
    let rm_counter = 0
    while rm_counter <= finish-start
      let file_todo = get(todo_file, rm_counter+start)
      call filter(a:lines, ''+file_todo)
      let rm_counter += 1
    endwhile

    call extend(todo_file, a:lines, finish-rm_counter-1)
  else
    " Insert new bock at end of file
    " TODO check if this works
    call insert(a:lines, 'FILE '.bufname("%").':', 0)
    call add(a:lines, '')
    call extend(todo_file, a:lines)
  endif

  call writefile(todo_file, todo_filename)
endfunction

" filename.ext: and then list all todos
function! SearchForTodos()
  " First look for todos in current buffer
  " TODO not for todo file types
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
  call SaveTodo(lines)
endfunction
