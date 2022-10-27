local TaskTypeMeta = {}

function TaskTypeMeta:__call(content)
    content.task_type = self
    return content
end

return TaskTypeMeta
