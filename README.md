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

## Notes
Source code file is authorative
Except for cancelled and done tasks, as well as tasks without line numbers

Cases
  1. User adds new todo in source code
  2. User removes todo in source code
  3. User changes todo text
  4. User changes source code so todo line number changes
  5. changes source code and todo tex
  6. User marks task as done in project todo
  7. User creates new tasks in project todo

Case 1: Create new todo
Case 2: Remove todo/mark as done
Case 3: like below
Case 4: Try to find matching todo and update
Case 5: Create new todo, then clean up orphaned todos without matches
Case 6: Remove todo line in source code
Case 7: Do nothing if there is no line number, simply keep at position

For now lets simply mark all removed tasks as done
and create new tasks for those that have no clear matches

