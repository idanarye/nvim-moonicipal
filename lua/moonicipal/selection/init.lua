---@generic T
---@alias MoonicipalSelectSource T[] | { [string]: T } | fun(cb: fun(item: T))

---@class (exact) MoonicipalSelectOptions
---@field prompt? string A prompt to display to the user when they select the option
---@field format? MoonicipalOptionTransformer How to display the options in the selection UI
---@field multi? boolean
---@field preview? fun(item: any): (string | string[])
---@field actions? string[] | {[string]: MoonicipalSelectActionOptions}

---@class (exact) MoonicipalSelectActionOptions
---@field multi? boolean
---@field query? boolean
