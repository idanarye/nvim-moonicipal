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
---@brief ]]
local M = {}

local util = require'moonicipal.util'
local tasks_file = require'moonicipal.tasks_file'

M.settings = require'moonicipal.settings'

local function get_file_name()
    return M.settings.file_prefix .. '.moonicipal.lua'
end

---@param config MoonicipalSettings
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
---@return Populator | fun(opts: Decoration) | MoonicipalTask
function M.tasks_file()
    return tasks_file.populator()
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

---@class MoonicipalInputOptions
---@field prompt? string
---@field default? string

---@param opts? MoonicipalInputOptions
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
---@field prompt? string
---@field format? MoonicipalOptionTransformer

---@param opts? MoonicipalSelectOptions
function M.select(options, opts)
    local new_opts = {}
    if opts then
        new_opts.prompt = opts.prompt
        if opts.format then
            new_opts.format_item = util.transformer_as_function(opts.format)
        end
    end
    return util.resume_with(function(resumer)
        vim.ui.select(options, new_opts, resumer)
    end)
end

function M.abort(msg)
    util.abort(msg)
end

function M.fix_echo()
    util.fix_echo()
end

function M.sleep(timeout)
    util.sleep(timeout)
end

function M.fake_scratch_buffer(set_buffer_name_to)
    util.fake_scratch_buffer(set_buffer_name_to)

end

function M.get_buf_contents(buf_nr)
    return util.get_buf_contents(buf_nr)
end

function M.set_buf_contents(buf_nr, content)
    util.set_buf_contents(buf_nr, content)
end

return M
