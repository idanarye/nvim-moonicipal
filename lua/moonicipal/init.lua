local M = {}

local tasks_file = require'moonicipal/tasks_file'

M.settings = require'moonicipal/settings'

function M.setup(config)
    for key, value in pairs(config) do
        M.settings[key] = value
    end
end

M.tasks_file = tasks_file.populator

function M.read_task_file()
    return tasks_file.load(M.settings.file_prefix .. '.moonicipal.lua')
end

return M
