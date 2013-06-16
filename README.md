# NotSoPlainTasks
This VIM extension is intended to keep the TODOs in your source code organized without disrupting your workflow.

## Installation
### Vundle
Add this to your .vimrc

    Bundle 'Gorgoroth/NotSoPlainTasks'

## Usage
NotSoPlainTasks does not disrupt your workflow, simply add and remove your TODOs in your source code as you always would.

### In your source code
Just work as normal, if there's a todo, just do this

    // TODO explain do_stuff function better

then save with :w, your task with be added to project.todo in your working dir. All tasks are grouped by source code filenames. If you remove the comment again and save, the task is toggled as done in the project.todo.

### In the project.todo
In your \*.todo-files, you can use the following keys in normal mode:

    + - create new task
    = - toggle complete
    <C-M> - toggle cancel
    - - archive tasks
    --<space> - insert a separator line
