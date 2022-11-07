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

-- Use a cached result when the task is called as a dependency
--
-- When the task is invoked as a main task, the function passed as argument will
-- always be called.
--
-- When the task is invoked as a dependency, the function will only be called if
-- the cache is empty. Otherwise, the cached result will be restored instead.
--
-- Note that the cache is task-bound - using this method multiple times in the
-- same task will use the same cache, even if the passed functions are
-- different.
--
--    function T:dependency()
--        return self:cache_result(function()
--            return moonicipal.input { prompt = "Enter text: " }
--        end)
--    end
--
--    function T:use()
--        local dependency_result = self:dep(T.dependency)
--        print('You have selected', vim.inspect(dependency_result))
--    end
---@generic T
---@generic P
---@param dlg fun(...: P): T
---@param ... P
---@return T
function TaskClass:cache_result(dlg, ...)
    local cached = self.cache[TaskClass.cache_result]
    if cached ~= nil and not self:is_main() then
        return unpack(cached)
    end
    local new_result = {dlg(...)}
    self.cache[TaskClass.cache_result] = new_result
    return unpack(new_result)
end

return TaskClass
