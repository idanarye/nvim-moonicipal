---@generic T
---@alias MoonicipalSelectSource T[] | { [string]: T } | fun(cb: fun(option: T))

---@class MoonicipalSelectOptions
---@field prompt? string A prompt to display to the user when they select the option
---@field format? MoonicipalOptionTransformer How to display the options in the selection UI
---@field multi? boolean
