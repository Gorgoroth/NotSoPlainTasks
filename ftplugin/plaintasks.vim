"Vim filetype plugin
" Language: PlainTasks
" Maintainer: David Elentok
" ArchiveTasks() added by Nik van der Ploeg

" Only do this when not done yet for this buffer
if exists("b:did_ftplugin")
  finish
endif

augroup NotSoPlainTasks
  autocmd BufWritePost * call SearchForTodos()
augroup END

nnoremap <buffer> + :call NewTask()<cr>A
nnoremap <buffer> = :call ToggleComplete()<cr>
nnoremap <buffer> <C-M> :call ToggleCancel()<cr>
nnoremap <buffer> - :call ArchiveTasks()<cr>
abbr -- <c-r>=Separator()<cr>

" when pressing enter within a task it creates another task
setlocal comments+=n:☐

function! ToggleComplete()
  let line = getline('.')
  if line =~ "^ *✔"
    s/^\( *\)✔/\1☐/
    s/ *@done.*$//
  elseif line =~ "^ *☐"
    s/^\( *\)☐/\1✔/
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

function! NewTask()
  let line=getline('.')
  if line =~ "^ *$"
    normal A☐
  else
    normal I☐
  end
endfunc

function! ArchiveTasks()
    let orig_line=line('.')
    let orig_col=col('.')
    let archive_start = search("^Archive:")
    if (archive_start == 0)
        call cursor(line('$'), 1)
        normal 2o
        normal iArchive:
        normal o＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿＿
        let archive_start = line('$') - 1
    endif
    call cursor(1,1)

    let found=0
    let a_reg = @a
    if search("✔", "", archive_start) != 0
        call cursor(1,1)
        while search("✔", "", archive_start) > 0
            if (found == 0)
                normal "add
            else
                normal "Add
            endif
            let found = found + 1
            call cursor(1,1)
        endwhile

        call cursor(archive_start + 1,1)
        normal "ap
    endif

    "clean up
    let @a = a_reg
    call cursor(orig_line, orig_col)
endfunc

function! Separator()
    let line = getline('.')
    if line =~ "^-*$"
      return "--- ✄ -----------------------"
    else
      return "--"
    end
endfunc

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
