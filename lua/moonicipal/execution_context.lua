local util = require'moonicipal/util'

local M = {}

function M:dep(task)
    task = self.tasks_file:get_task(task)
    local existing_result = self.invoked_tasks_results[task]
    if type(existing_result) == 'table' then
        return unpack(existing_result)
    elseif existing_result == true then
        error('Deadlock when trying to invoke ' .. vim.inspect(task.name) .. ' as dependency')
    else
        assert(existing_result == nil)
        self:run(task)
        return unpack(self.invoked_tasks_results[task])
    end
end

local CACHE = {}

function M:run(task_def)
    local task_instance = {
        context = self,
        task_def = task_def,
        cache = CACHE[task_def.name] or {},
    }
    setmetatable(task_instance, {
        __index = require'moonicipal/task_class',
    })
    self.invoked_tasks_results[task_def] = true
    local result = {task_def.run(task_instance)}
    local cache = rawget(task_instance, 'cache')
    vim.validate {
        cache = {cache, 'table'}
    }
    CACHE[task_def.name] = cache
    self.invoked_tasks_results[task_def] = result
end

return function(tasks_file)
    return vim.tbl_extend('error', {
        tasks_file = tasks_file;
        invoked_tasks_results = {};
    }, M)
end
