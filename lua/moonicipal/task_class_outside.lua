---@class MunicipalTaskOutside
local M = {}

local execution_context = require'moonicipal/execution_context'

function M:__call()
    local context = execution_context()
    return context:run(self)
end

return M
