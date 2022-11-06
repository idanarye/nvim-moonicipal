---@class TaskClass
---@field task_def table
---@field context table
---@field cache table Data that will be there on the new run
local TaskClass = {}

-- Run another task if it hasn't been run before this execution
---@generic T
---@param task fun(self: any): T
---@return T
function TaskClass:dep(task)
    return self.context:dep(task)
end

--- Check if this is the entry task of the current execution
---@return
---| true # if this task was invoked directly from a user command
---| false # if this task was invoked as a dependency of another task
function TaskClass:is_main()
    return self.context.main_task == self.task_def
end

return TaskClass
