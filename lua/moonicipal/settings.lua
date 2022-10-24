local META = {
}

local DEFAULTS_KEY = {}

function META:new(defaults)
    return setmetatable({[DEFAULTS_KEY] = defaults}, self)
end

function META:__index(name)
    local defaults = rawget(self, DEFAULTS_KEY)
    local value = rawget(self, name)
    if value == nil then
        return defaults[name]
    else
        return value
    end
end

function META:__newindex(name, value)
    local defaults = rawget(self, DEFAULTS_KEY)
    if defaults[name] == nil then
        error(name .. ' is not a valid Moonicipal setting')
    end
    rawset(self, name, value)
end

return META:new {
    file_prefix = '.' .. (os.getenv('USER') or os.getenv('USERNAME'));
}
