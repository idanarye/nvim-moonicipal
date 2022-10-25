local M = {}

local tasks_file = require'moonicipal/tasks_file'
local util = require'moonicipal/util'

M.settings = require'moonicipal/settings'

function M.setup(config)
    for key, value in pairs(config) do
        M.settings[key] = value
    end
end

function M.tasks_file()
    return tasks_file.populator()
end

function M.invoke(task_name)
    M.read_task_file():invoke(task_name)
end

function M.read_task_file()
    return tasks_file.load(M.settings.file_prefix .. '.moonicipal.lua')
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