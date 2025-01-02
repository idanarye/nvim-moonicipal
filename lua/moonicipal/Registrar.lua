local MoonicipalTaskOutside = require'moonicipal.task_class_outside'

---The object used for registering tasks insides a tasks file, and for invoking
---other tasks as dependencies.
---@class MoonicipalRegistrar
local Registrar = {}

---@brief [[
---Moonicipal tasks are registered as methods on the registrar, but unlike
---regular Lua semantics the registrar is not the `self` of these methods: >
---    function T:registrar_and_task_self_are_different()
---        assert(self ~= T)
---    end
---<
---The `self` passed to these methods is a |MoonicipalTask|, used mainly for
---accessing the task's cache. Meanwhil the registrar can be used from inside a
---task to access other methods: >
---    function T:dependency()
---        return 42
---    end
---
---    function T:dependant_user()
---        local value_from_dependency = T:dependency()
---        assert(value_from_dependency == 42)
---    end
---<
---@brief ]]

---Passed to the registrar object as a function argument to configure the next
---task:
---    T { alias = 'other_name_for_the_task' }
---    function T:some_task()
---        -- task body
---    end
---@class MoonicipalRegistrarDecoration
---Allow invoking the task by some other name.
---Will not show in the tasks list.
---@field alias string | string[]

---
---@see MoonicipalRegistrarDecoration
function Registrar:__call(decoration)
    if rawget(self, 'decoration') then
        error('Only one decoration allowed per task', 2)
    end
    rawset(self, 'decoration', decoration)
end

---Invoke another task as dependency:
---    function T:dependency()
---        return 42
---    end
---
---    function T:dependant_user()
---        local value_from_dependency = T:dependency()
---        assert(value_from_dependency == 42)
---    end
function Registrar:__index(task_name)
    return rawget(self, 'tasks')[task_name]
end

local function as_iterator(value)
    if value == nil then
        return function()
            -- Do nothing - empty iteration
        end
    elseif vim.islist(value) then
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

---Register a task assigning a function to the registrar object:
---    T['task-name'] = function()
---        -- task body
---    end
---
---Prefer using Lua's method declaration syntax:
---    function T.task_name()
---        -- task body
---    end
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
