local M = {}

local old_executions = {}
local current_execution = {}

local function get_or_create_current_cache(task_name)
    local task_cache = current_execution[task_name]
    if task_cache == nil then
        task_cache = {
            still_valid = function()
                return true
            end;
        }
        current_execution[task_name] = task_cache
    end
    return task_cache
end

function M.cycle(tasks_file)
    for k, v in pairs(current_execution) do
        old_executions[k] = v
        current_execution[k] = nil
    end
    for k in pairs(old_executions) do
        if tasks_file.tasks[k] == nil then
            old_executions[k] = nil
        end
    end
end

function M.set_data(task_name, ...)
    get_or_create_current_cache(task_name).data = {...}
end

function M.set_still_valid(task_name, still_valid)
    get_or_create_current_cache(task_name).still_valid = still_valid
end

function M.get_data(task_name)
    local task_cache = current_execution[task_name]
    if task_cache ~= nil and task_cache.data ~= nil then
        return unpack(task_cache.data)
    end
    task_cache = old_executions[task_name]
    if task_cache ~= nil and task_cache.data ~= nil and task_cache.still_valid() then
        return unpack(task_cache.data)
    end
end

return M
