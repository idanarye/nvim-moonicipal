local util = require'moonicipal.util'

---Object for registering chocies for a user to select.
---@class MoonicipalCachedChoice: MoonicipalCachedChoiceConfiguration
---@operator call(number): string
local CachedChoice = {}
CachedChoice.__index = CachedChoice

---Add an option for the user to select.
---@param option any The options for the user to select
function CachedChoice:__call(option)
    table.insert(self, option)
end

---Let the user choose using `moonicipal.selected`.
---
---When called from the main task, will always prompt the user to choose an
---option. When called from another task, will only prompt the user to choose
---an option if there is no selection in the cache, or if the cached selection
---is no longer available.
---@return any # The chosen option
function CachedChoice:select()
    assert(self.key, '`cached_choice` used without setting a key')
    local key_fn = util.transformer_as_function(self.key)

    if not self.task:is_main() then
        local cached_key = self.task.cache[CachedChoice]
        if cached_key ~= nil then
            for _, option in ipairs(self) do
                if key_fn(option) == cached_key then
                    return option
                end
            end
        end
    end

    local chosen = require'moonicipal'.select(self, {
        format = self.format,
    })
    self.task.cache[CachedChoice] = key_fn(chosen)
    return chosen
end

return CachedChoice
