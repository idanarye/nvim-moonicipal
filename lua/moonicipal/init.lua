---@mod moonicipal Moonicipal - Task Runner for Rapidly Changing Personal Tasks
---@brief [[
---Moonicipal is a task runner that focuses on personal tasks that are easy to
---write and to change:
---
---* Task files are personal - users can edit them without breaking the
---  workflow for other developers that use the same project.
---* Tasks are Lua functions that run inside Neovim - they can can easily
---  access all of Neovim's context and functionalities, and easily interact
---  with other Neovim plugins.
---* The task functions always run in coroutines, and some helpers are provided
---  for writing async code instead of using callbacks.
---* The task file is reloaded each time a user runs a task, so it can be
---  edited rapidly.
---* Caching facilities for saving things like build configuration or
---  test/example-to-run without having to change the tasks file each time.
---
---Moonicipal is the successor to the Pythonic test runner Omnipytent
---(https://github.com/idanarye/vim-omnipytent). Since Moonicipal is written in
---Lua and executes tasks that are written in Lua, it allows for better
---integration with Neovim and with Lua plugins and for simpler semantics of
---asynchronous tasks.
---@brief ]]

---@toc moonicipal.contents
---@divider =

local M = {}

local util = require'moonicipal.util'
local tasks_file = require'moonicipal.tasks_file'

M.settings = require'moonicipal.settings'

local function get_file_name()
    return M.settings.file_prefix .. '.moonicipal.lua'
end

---Configure Moonicipal and create the Vim commands.
---@param config MoonicipalSettings
---@see MoonicipalSettings
function M.setup(config)
    for key, value in pairs(config) do
        M.settings[key] = value
    end

    local function cmd_complete(arg_lead)
        return vim.tbl_filter(function(task_name)
            return vim.startswith(task_name, arg_lead)
        end, vim.tbl_keys(M.read_task_file().tasks))
    end

    vim.api.nvim_create_user_command('MC', function(ctx)
        if ctx.fargs[1] == nil then
            M.read_task_file():select_and_invoke()
        else
            M.read_task_file():invoke(unpack(ctx.fargs))
        end
    end, { nargs = '*', complete = cmd_complete })

    -- These are all temporary. Will be replaced with more proper solution
    local function define_edit_function(cmd_name, edit_cmd)
        vim.api.nvim_create_user_command(cmd_name, function(ctx)
            tasks_file.open_for_edit(edit_cmd, get_file_name(), unpack(ctx.fargs))
        end, { nargs = '?', complete = cmd_complete })
    end
    define_edit_function('MCedit', 'edit')
    define_edit_function('MCsedit', 'split')
    define_edit_function('MCvedit', 'vsplit')
    define_edit_function('MCtedit', 'tabnew')
end

---@private
---@return MoonicipalRegistrar | fun(opts: MoonicipalRegistrarDecoration) | MoonicipalTask | table
function M.tasks_file()
    return tasks_file.registrar()
end

---@private
function M.select_and_invoke()
    M.read_task_file():select_and_invoke()
end

---@private
function M.invoke(task_name, ...)
    M.read_task_file():invoke(task_name, ...)
end

---@private
function M.read_task_file()
    return tasks_file.load(get_file_name())
end

---Fields for the `opts` argument of |moonicipal.input|.
---@class MoonicipalInputOptions
---@field prompt? string A prompt to display to the user when they enter the text
---@field default? string A default text the user can confirm or edit

---Use |vim.ui.input()| from a Lua coroutine, returning to the coroutine after
---the user entered text.
---@param opts? MoonicipalInputOptions
---@return string|nil # The text entered by the user
function M.input(opts)
    local new_opts = {}
    if opts then
        new_opts.prompt = opts.prompt
        new_opts.default = opts.default
    end
    return util.resume_with(function(resumer)
        vim.ui.input(new_opts, resumer)
    end)
end

---@class MoonicipalSelectOptions
---@field prompt? string A prompt to display to the user when they select the option
---@field format? MoonicipalOptionTransformer How to display the options in the selection UI

---Use |vim.ui.select()| from a Lua coroutine, returning to the coroutine after
---the user selected an option.
---@param options any[] The options for the user to select from
---@param opts? MoonicipalSelectOptions
function M.select(options, opts)
    local new_opts = {}
    if opts then
        new_opts.prompt = opts.prompt
        if opts.format then
            new_opts.format_item = util.transformer_as_function(opts.format)
        end
    end
    if new_opts.format_item == nil then
        function new_opts.format_item(item)
            if type(item) == 'string' then
                return item
            else
                return vim.inspect(item)
            end
        end
    end
    return util.resume_with(function(resumer)
        vim.ui.select(options, new_opts, resumer)
    end)
end

---Abort the Moonicipal invocation.
---
---Unlike a regular `error`, which will be caught and make Moonicipal print the
---stack trace of the error, `moonicipal.abort` will only print the message.
function M.abort(msg)
    util.abort(msg)
end

---When a coroutine is resumed from a Neovim callback, lines printed from Vim's
---|:echo| or Lua's `print` will not stack up. Calling this will make them
---stack again (until the coroutine is paused and resumed from a callback again)
function M.fix_echo()
    util.fix_echo()
end

---Pause the coroutine for the specified duration
---@param milliseconds number The duration to sleep for, in milliseconds
function M.sleep(milliseconds)
    util.sleep(milliseconds)
end

---Make the current buffer a scratch buffer.
---
---This is similar to `:set buftype=nofile`, except the buffer can work with
---LSP clients.
---@param set_buffer_name_to? string Manually set a name for the buffer
function M.fake_scratch_buffer(set_buffer_name_to)
    util.fake_scratch_buffer(set_buffer_name_to)
end

---Get the contents of a buffer as a single string.
---@param buf_nr number The buffer number
---@return string
function M.get_buf_contents(buf_nr)
    return util.get_buf_contents(buf_nr)
end

---Set the content of a buffer
---@param buf_nr number The buffer number
---@param content string|string[] The content to set
function M.set_buf_contents(buf_nr, content)
    util.set_buf_contents(buf_nr, content)
end

return M
