---@class TaskClass
---@field task_def table
---@field context table
---@field cache table Data that will be there on the new run
local TaskClass = {}

-- Run another task if it hasn't been run before this execution.
---@generic T
---@param task fun(self: any): T
---@return T
function TaskClass:dep(task)
    return self.context:dep(task)
end

--- Check if this is the entry task of the current execution.
---@return
---| true # if this task was invoked directly from a user command
---| false # if this task was invoked as a dependency of another task
function TaskClass:is_main()
    return self.context.main_task == self.task_def
end

-- Use a cached result when the task is called as a dependency.
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

-- Create a buffer, and use the result only if the buffer is still open in the
-- current tab.
--
-- See `cache_result` for other notes about the cache. The buffer used for the
-- caching is the buffer Vim ends up in when the passed function returns.
--
--    function T:log_buffer()
--        return self:cached_buf_in_tab(function()
--            vim.cmd[[new]]
--            vim.o.buftype = 'nowrite'
--            local buf_nr = vim.api.nvim_buf_get_number(0)
--            return function(text)
--                vim.api.nvim_buf_set_lines(buf_nr, -1, -1, true, { text })
--            end
--        end)
--    end
--
--    function T:log()
--        local log_buffer = self:dep(T.log_buffer)
--        log_buffer(moonicipal.input())
--    end
---@generic T
---@generic P
---@param dlg fun(...: P): T
---@param ... P
---@return T
function TaskClass:cached_buf_in_tab(dlg, ...)
    local cache_key = 'Moonicipal:cached_buf_in_tab:' .. self.task_def.name
    for _, win_nr in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf_nr = vim.api.nvim_win_get_buf(win_nr)
        local has_cache, cache = pcall(vim.api.nvim_buf_get_var, buf_nr, cache_key)
        if has_cache then
            return unpack(cache)
        end
    end

    local result = {dlg(...)}
    vim.b[cache_key] = result
    return unpack(result)
end

return TaskClass
