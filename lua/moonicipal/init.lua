local M = {}

local tasks_file = require'moonicipal/tasks_file'
local util = require'moonicipal/util'

M.settings = require'moonicipal/settings'

local function get_file_name()
    return M.settings.file_prefix .. '.moonicipal.lua'
end

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
        M.invoke(unpack(ctx.fargs))
    end, { nargs = '*', complete = cmd_complete })

    -- These are all temporary. Will be replaced with more proper solution
    vim.api.nvim_create_user_command('MCedit', function()
        vim.cmd('edit ' .. get_file_name())
    end, {})
    vim.api.nvim_create_user_command('MCsedit', function()
        vim.cmd('split ' .. get_file_name())
    end, {})
    vim.api.nvim_create_user_command('MCvedit', function()
        vim.cmd('vsplit ' .. get_file_name())
    end, {})
    vim.api.nvim_create_user_command('MCtedit', function()
        vim.cmd('tabnew ' .. get_file_name())
    end, {})
end

function M.tasks_file()
    return tasks_file.populator()
end

function M.invoke(...)
    M.read_task_file():invoke(...)
end

function M.read_task_file()
    return tasks_file.load(get_file_name())
end

function M.sleep(timeout)
    util.sleep(timeout)
end

function M.fix_echo()
    util.fix_echo()
end

function M.input(opts)
    return util.resume_with(function(resumer)
        vim.ui.input(opts, resumer)
    end)
end

function M.select(options, opts)
    return util.resume_with(function(resumer)
        vim.ui.select(options, opts, resumer)
    end)
end

return M
