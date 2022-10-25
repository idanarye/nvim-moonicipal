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

function T:invoke(task_name)
    local task = self.tasks[task_name]
    local co = coroutine.create(function()
        xpcall(task.run, function(error)
            local traceback = debug.traceback(error, 2)
            traceback = string.gsub(traceback, '\t', string.rep(' ', 8))
            vim.api.nvim_err_writeln(traceback)
        end)
    end)
    coroutine.resume(co)
end

return M
