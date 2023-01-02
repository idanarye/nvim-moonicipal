local MoonicipalTaskOutside = require'moonicipal.task_class_outside'

---@class MoonicipalRegistrar
local Registrar = {}


function Registrar:__call(decoration)
    if rawget(self, 'decoration') then
        error('Only one decoration allowed per task', 2)
    end
    rawset(self, 'decoration', decoration)
end

function Registrar:__index(task_name)
    return rawget(self, 'tasks')[task_name]
end

local function as_iterator(value)
    if value == nil then
        return function()
            -- Do nothing - empty iteration
        end
    elseif vim.tbl_islist(value) then
        return ipairs(value)
    else
        local need_to_send = true
        return function()
            if need_to_send then
                need_to_send = false
                return 1, value
            end
        end
    end
end

function Registrar:__newindex(task_name, task_run_function)
    vim.validate {
        {task_run_function, 'function'};
    }
    local decoration = rawget(self, 'decoration') or {}
    rawset(self, 'decoration', nil)
    local tasks = rawget(self, 'tasks')
    local task_def = setmetatable({
        name = task_name,
        run = task_run_function,
    }, MoonicipalTaskOutside)
    table.insert(rawget(self, 'task_names_by_order'), task_name)
    tasks[task_name] = task_def
    for _, alias in as_iterator(decoration.alias) do
        tasks[alias] = task_def
    end
end

return Registrar
