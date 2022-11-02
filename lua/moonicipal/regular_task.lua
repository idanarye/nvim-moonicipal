local RegularTask = setmetatable({}, require'moonicipal/task_type_meta')

local task_methods = {}

function RegularTask:run(context, task_def, args)
    local task_instance = vim.tbl_extend('error', {
        context = context;
        task_def = task_def;
        args = args;
    }, task_methods)
    context.invoked_tasks_results[task_def] = true
    local result = {task_def.run(task_instance)}
    context.invoked_tasks_results[task_def] = result
end

function task_methods:dep(...)
    return self.context:dep(...)
end

function task_methods:is_main()
    return self.context.main_task == self.task_def
end

return RegularTask
