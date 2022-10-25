local util = require'moonicipal/util'

local M = {}


local P = {}
function M.populator()
    return setmetatable({}, P)
end

function P:__newindex(task_name, task_def)
    if type(task_def) == 'function' then
        M.current[task_name] = {
            name = task_name;
            run = task_def;
        }
    elseif type(task_def) == 'table' then
        if task_def.name == nil then
            task_def.name = task_name
            M.current[task_name] = task_def
        end
    end
end

local T = {}
function M.load(path)
    local tasks = {}
    M.current = tasks
    loadfile(path)()
    M.current = nil
    return vim.tbl_extend('error', T, {
        tasks = tasks;
    })
end

function T:invoke(...)
    local args = {...}
    util.defer_to_coroutine(function()
        local task_name = args[1]
        if not task_name then
            task_name = util.resume_with(function(resumer)
                vim.ui.select(vim.tbl_keys(self.tasks), {
                    prompt = 'Choose task to run: ';
                }, resumer)
            end)
            if not task_name then
                return
            end
            util.fix_echo()
        end
        local task = self.tasks[task_name]
        task.run()
    end)
end

return M
