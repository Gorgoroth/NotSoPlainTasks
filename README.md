# NotSoPlainTasks
This VIM extension is intended to keep the TODOs in your source code organized without disrupting your workflow.

## Principles
In line with pragmatic programming principles, this plugin generates documentation directly from your source code. There is no extra overhead involved, just extra convenience. The source code is your documentation, as it should be.

Every source code comment that starts with TODO is automatically recognized as a task. When you save your work, all tasks are automatically compiled into a project.todo in your working dir root. All tasks are grouped by the source code file name.

If you delete a TODO code comment and save your work, that task is automatically marked as done and put into a fold in the file group.

The project.todo file uses the PlainTasks syntax and highlighting. Enhanced functions include, e.g. 'gf', which takes you directly to the source code file and line of the task.

## Installation
### Vundle
Add this to your .vimrc or bundle file

    Bundle 'Gorgoroth/NotSoPlainTasks'

## Usage
NotSoPlainTasks does not disrupt your workflow, simply add and remove your TODOs in your source code as you always would.

### In your source code
#### Adding a new tasks in source code
Just work as normal, if there's a todo, just do this

    // TODO explain do_stuff function better

then save with :w, your task with be added to project.todo in your working dir. All tasks are grouped by source code filenames. If you remove the comment again and save, the task is toggled as done in the project.todo.

#### Indexing all tasks in project
Hit

    <Leader>nptg

to generate a project.todo from all files in your working directory

### In the project.todo
In your \*.todo-files, you can use the following keys in normal mode:

    <Leader>nptn - new task
    <Leader>nptj - jump, same as gf below
    gf           - jump to file and line of task under cursor
    <Leader>nptd - done with task, currently jumps to file and line of task under cursor
    <Leader>nptc - clean tasks, removes all done tasks from project.todo

## Notes
Source code file is authorative, except for cancelled and done tasks, as well as tasks without line numbers

NotSoPlainTasks will try to update your open tasks as good as it can. There are limitations, however. If the line number and content of a coment changes, it will mark the task as done and create a new one. To work around these issues, save often, if you don't already.

## Feedback
Please let me know if you'd like to see new features or see something that could be solved better!

## Thanks
elentok for the Vim PlainTasks implementation that is the root of this project.
