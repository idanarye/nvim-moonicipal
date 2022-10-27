local args_context = require'moonicipal/args_context'

local RegularTask = setmetatable({}, require'moonicipal/task_type_meta')

function RegularTask:run(context, task_def, args)
    local task_instance = {}
    if task_def.args then
        local extracted = args_context.extract(task_def.args, {unpack(args or {})})
        task_instance = vim.tbl_extend('error', task_instance, extracted)
    end
    task_def.run(task_instance)
end

return RegularTask
