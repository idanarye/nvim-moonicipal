local MoonicipalRegistrar = require'moonicipal.Registrar'

local M = {}

function M.new()
    return setmetatable({
        tasks = {},
        task_names_by_order = {},
    }, MoonicipalRegistrar)
end

---@class MoonicipalMergedRouter
local MergedRouter = {}

function MergedRouter:__index(task_name)
    for index, lib in ipairs(self) do
        if rawget(lib, "tasks")[task_name] then
            return function(...)
                return self[index][task_name](...)
            end
        end
    end
end

function M.merge_libs(...)
    local children = {}
    for _, lib in ipairs({...}) do
        if getmetatable(lib) == MergedRouter then
            vim.list_extend(children, lib)
        else
            table.insert(children, lib)
        end
    end
    return setmetatable(children, MergedRouter)
end

return M
