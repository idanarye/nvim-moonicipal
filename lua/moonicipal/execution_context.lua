local util = require'moonicipal/util'

local M = {}

function M:dep(task_name)
    local task = self.tasks_file:get_task(task_name)
    local existing_result = self.invoked_tasks_results[task]
    if type(existing_result) == 'table' then
        return unpack(existing_result)
    elseif existing_result == true then
        error('Deadlock when trying to invoke ' .. vim.inspect(task_name) .. ' as dependency')
    else
        assert(existing_result == nil)
        task.task_type:run(self, task, nil)
        return unpack(self.invoked_tasks_results[task])
    end
end

return function(tasks_file)
    return vim.tbl_extend('error', {
        tasks_file = tasks_file;
        invoked_tasks_results = {};
    }, M)
end
