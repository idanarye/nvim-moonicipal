local M = {}

local P = {}
function M.populator()
    return setmetatable({}, P)
end

function P:__newindex(task_name, task_def)
    if type(task_def) == 'table' then
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

function T:invoke(task_name)
    local task = self.tasks[task_name]
    local co = coroutine.create(task.run)
    coroutine.resume(co)
end

return M
