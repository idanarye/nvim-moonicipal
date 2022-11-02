local cache = require('moonicipal/cache')

local RegularTask = setmetatable({}, require'moonicipal/task_type_meta')

local RegularTaskMeta = {
    methods = {};
    getters = {};
    setters = {};
}

function RegularTaskMeta:__index(name)
    local metatable = getmetatable(self)

    local method = metatable.methods[name]
    if method ~= nil then
        return method
    end

    local getter = metatable.getters[name]
    if getter ~= nil then
        return getter(self)
    end

    return rawget(self, name)
end

function RegularTaskMeta:__newindex(name, value)
    local metatable = getmetatable(self)
    local setter = metatable.setters[name]
    if setter ~= nil then
        setter(self, value)
        return
    end
    if metatable.methods[name] ~= nil then
        error(name .. ' is a method - cannot set')
    end
    if metatable.getters[name] ~= nil then
        error(name .. ' is a property - cannot set')
    end
    rawset(self, name, value)
end

function RegularTask:run(context, task_def, args)
    local task_instance = {
        context = context;
        task_def = task_def;
        args = args;
    }
    setmetatable(task_instance, RegularTaskMeta)
    context.invoked_tasks_results[task_def] = true
    local result = {task_def.run(task_instance)}
    context.invoked_tasks_results[task_def] = result
end

function RegularTaskMeta.methods:dep(...)
    return self.context:dep(...)
end

function RegularTaskMeta.methods:is_main()
    return self.context.main_task == self.task_def
end

function RegularTaskMeta.getters:cache()
    return cache.get_data(self.task_def.name)
end

function RegularTaskMeta.setters:cache(...)
    return cache.set_data(self.task_def.name, ...)
end

function RegularTaskMeta.setters:cache_still_valid(pred)
    return cache.set_still_valid(self.task_def.name, pred)
end

return RegularTask
