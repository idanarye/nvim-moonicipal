local util = require'moonicipal/util'

local M = {}

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
    local result = {task_def.run(task_instance)}
    local cache = rawget(task_instance, 'cache')
    vim.validate {
        cache = {cache, 'table'}
    }
    CACHE[task_def.name] = cache
    return unpack(result)
end

return function()
    return vim.tbl_extend('error', {
    }, M)
end
