local util = require'moonicipal/util'
local RegularTask =require'moonicipal/regular_task'

local M = {}


local P = {}
function M.populator()
    return setmetatable({}, P)
end

function P:__call(prepare)
    vim.validate {
        prepare = {prepare, 'table'};
    }
    rawset(self, 'prepare', prepare)
end

function P:__index()
    error('Cannot get stuff from the tasks file populator')
end

function P:__newindex(task_name, task_def)
    vim.validate {
        prepare = {task_def, 'function'};
    }
    if type(task_def) == 'function' then
        local prepare = rawget(self, 'prepare') or {}
        rawset(self, 'prepare', nil)
        if not prepare.task_type then
            prepare.task_type = RegularTask
        end
        prepare.name = task_name
        prepare.run = task_def
        M.current[task_name] = prepare
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
        local context = {}
        local task_name = args[1]
        local task_args = {select(2, unpack(args))}
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
        task.task_type:run(context, task, task_args)
    end)
end

return M
