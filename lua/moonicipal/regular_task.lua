local RegularTask = setmetatable({}, require'moonicipal/task_type_meta')

function RegularTask:run(context, task_def, args)
    local task_instance = {
        args = args;
    }
    task_def.run(task_instance)
end

return RegularTask
