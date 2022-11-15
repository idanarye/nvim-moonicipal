local META = {
}

local DEFAULTS_KEY = {}

---@return MoonicipalSettings
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

---@class MoonicipalSettings
---@field file_prefix? string
---@field tasks_selection_lru_size? number
return META:new {
    file_prefix = '.' .. (os.getenv('USER') or os.getenv('USERNAME')),
    tasks_selection_lru_size = 5,
}
