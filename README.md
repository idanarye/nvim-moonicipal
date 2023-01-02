[![CI Status](https://github.com/idanarye/nvim-moonicipal/workflows/CI/badge.svg)](https://github.com/idanarye/nvim-moonicipal/actions)

INTRODUCTION
============

Moonicipal is a task runner that focuses on personal tasks that are easy to
write and to change:

* Task files are personal - users can edit them without breaking the workflow for other developers that use the same project.
* Tasks are Lua functions that run inside Neovim - they can can easily access all of Neovim's context and functionalities, and easily interact with other Neovim plugins.
* The task functions always run in coroutines, and some helpers are provided for writing async code instead of using callbacks.
* The task file is reloaded each time a user runs a task, so it can be edited rapidly.
* Caching facilities for saving things like build configuration or test/example-to-run without having to change the tasks file each time.

Moonicipal is the successor to [Omnipytent](https://github.com/idanarye/vim-omnipytent), but written in Lua and executes tasks that are written in Lua. This allows for better integration with Neovim and with Lua plugins and for easier asynchronous tasks.

FEATURES (IMPLEMENTED/PLANNED)
==============================

* [x] Task file editing.
* [x] Running tasks by name.
* [x] Running tasks with selection UI.
* [x] Tasks run in coroutines.
* [x] Helpers for writing async tasks.
* [x] Utilities for caching user selections.
* [ ] Support setting up custom selection UI, for utilizing the full power of FZF/Telescope.
* [ ] Use custom selection UI for rich `:MC` selection menu, where e.g. keymaps can be used to edit tasks instead of running them.
* [ ] Customizing the tasks file template.
* [ ] null-ls source with customizable code actions for creating commonly used tasks.
* [ ] Allow writing the tasks file in Fennel (and other Lua based languages?)

QUICK START
===========

In a project, run `:MCedit build` which will open a new tasks file that looks like this:

```lua
local moonicipal = require'moonicipal'
local T = moonicipal.tasks_file()

function T:build()
    |
end
```

Where `|` is the location of the cursor in insert mode. Write your task - for example, let's use `vim.cmd` to run Vim's `:make` command:

```lua
local moonicipal = require'moonicipal'
local T = moonicipal.tasks_file()

function T:build()
    vim.cmd.make()
end
```

Save the tasks file, and run `:MC build`. Alternatively, run `:MC` and pick `build` using Neovim's selection UI. This will run your task.

Use `:MCedit` again (with or without parameter) to go back to the task file and edit it whenever you want.

SUPPLEMENTAL PLUGINS
====================

Moonicipal tasks, being Lua functions that run in Neovim's context, can use any Neovim plugin with ease. There are, however, some supplemental plugins that do not depend on it but were created in order to run inside Moonicipal tasks. The can be used separately but will probably not be as useful without Moonicipal.

* [Channelot](https://github.com/idanarye/nvim-channelot) - for running and controlling jobs, with or without a terminal. Job control is based on Lua coroutines, so Moonicipal tasks can easily use it without have to use the callbacks of Neovim's regular job API.
* [BuffLS](https://github.com/idanarye/nvim-buffls) - a null-ls source that can be customized for a specific buffer. Works great with Moonicipal's `cached_data_cell`, where it allows to easily add code actions and completions tailored for the specific data cell inside the Moonicipal action that creates it.

CONTRIBUTION GUIDELINES
=======================

* If your contribution can be reasonably tested with automation tests, add tests. The tests run with [a specific branch in a fork of Plenary](https://github.com/idanarye/plenary.nvim/tree/async-testing) that allows async testing ([there is a PR to include it in the main repo](https://github.com/nvim-lua/plenary.nvim/pull/426))
* Documentation comments must be compatible with both [Sumneko Language Server](https://github.com/sumneko/lua-language-server/wiki/Annotations) and [lemmy-help](https://github.com/numToStr/lemmy-help/blob/master/emmylua.md). If you do something that changes the documentation, please run `make docs` to update the vimdoc.
* Update the changelog according to the [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) format.
