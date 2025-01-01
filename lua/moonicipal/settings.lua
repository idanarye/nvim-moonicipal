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

---Settings for |moonicipal.setup|.
---@class MoonicipalSettings
---A prefix for the name of the Moonicipal tasks file.
---The tasks file will end up being named
---"`<file_prefix>.moonicipal.lua`". Defaults to `.$USER`.
---@field file_prefix? string
---|:MC| without argument will remember the last tasks
---the user has chosen and put them at the start of the
---list. This parameter controls how many tasks can be
---remembered. Defaults to 5.
---@field tasks_selection_lru_size? number
---The selection UI used by |moonicipal.select| - which means it'll also be
---used by other Moonicipal facilities like |:MC| or
---|MoonicipalTask:cached_choice|.
---Defaults to "moonicipal.selection.builtin", which uses |vim.ui.select()|,
---but "moonicipal.selection.fzf-lua" and "moonicipal.selection.telescope" are
---also available out of the box (as long as the respective backend plugin is
---installed).
---@field selection? string | function
local Settings = {
    file_prefix = '.' .. (os.getenv('USER') or os.getenv('USERNAME')),
    tasks_selection_lru_size = 5,
    selection = 'moonicipal.selection.builtin',
}

return Settings
