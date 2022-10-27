local M = {}

local ARGUMENT_TYPES = {
    pos = {
        extract = function(self)
            return table.remove(self, 1)
        end;
    };
}

local MISSING = setmetatable({}, {
    __tostring = function()
        return '<MISSING ARGUMENT>'
    end;
})

local ParseMeta = {}
function ParseMeta:__index(name)
    local extract = ARGUMENT_TYPES[name].extract
    return function(...)
        local arg = extract(rawget(self, 'input'), ...)
        if arg == nil then
            return MISSING
        end
        return arg
    end
end
function ParseMeta:__newindex(name, value)
    if MISSING == value then
        error('Missing argument ' .. name)
    end
    rawget(self, 'output')[name] = value
end

function M.extract(args_def, input)
    local output = {}
    args_def(setmetatable({input = input, output = output}, ParseMeta))
    return output
end

return M
