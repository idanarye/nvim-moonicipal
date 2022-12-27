---@mod moonicipal-setup Moonicipal setup
---@brief [[
---Add this to your `init.lua`:
--->
---    require'moonicipal'.setup {
---        file_prefix = '.my-username',
---    }
---<
---`file_prefix` is optional - if left unset, Moonicipal will set it using the
---username form the OS. See |MoonicipalSettings| for more setup options.
---@brief ]]

---@mod moonicipal-quick-start Moonicipal quick start
---@brief [[
---In a project, run `:MCedit build` (see |:MCedit|) which will open a new
---tasks file that looks like this: >
---    local moonicipal = require'moonicipal'
---    local T = moonicipal.tasks_file()
---
---    function T:build()
---        |
---    end
---<
---Where `|` is the location of the cursor in insert mode. Write your task -
---for example, let's use |vim.cmd| to run Vim's |:make| command: >
---    local moonicipal = require'moonicipal'
---    local T = moonicipal.tasks_file()
---
---    function T:build()
---        vim.cmd.make()
---    end
---<
---Save the tasks file, and run `:MC build` (see |:MC|). Alternatively, run
---`:MC` and pick `build` using Neovim's selection UI. This will run your task.
---
---Use `:MCedit` again (with or without parameter) to go back to the task file
---and edit it whenever you want.
---@brief ]]

---@mod moonicipal-commands Moonicipal Commands
---@brief [[
---These commands will only be created after `require'moonicipal'.setup()` is
---called (see |moonicipal-setup|)
---@brief ]]

---@tag :MC
---@brief [[
---The `:MC` command invokes tasks. Given a task name as argument, it invokes
---the task with that name. When used without arguments, it uses
---|vim.ui.select()| to prompt you to choose a task, and then runs that task.
---@brief ]]

---@tag :MCedit
---@brief [[
---The `:MCedit` command opens the tasks file for editing. If there is no task
---file for the current project (no file with the appropriate name in the
---current working directory), a new buffer will be opened for that file with a
---basic template that imports Moonicipal and initializes a tasks file.
---
---Given a task name as argument, a scaffold for a new task with that name will
---be created in the tasks file, and Neovim will go into insert mode in the
---appropriate position for writing the first command for that task. If a task
---with that name already exists, Neovim will jump to that task but will not
---add a scaffold and will not go into insert mode.
---@brief ]]

---@tag :MCsedit
---@tag :MCvedit
---@tag :MCtedit
---@brief [[
---`:MCsedit`, `:MCvedit` and `:MCtedit` are similar to |:MCedit|, but open the
---task file in a new split, vertical split, or tab.
---@brief ]]

local M = {}
return M
