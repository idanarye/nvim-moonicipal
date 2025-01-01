---@generic T
---@alias MoonicipalSelectSource T[] | { [string]: T } | fun(cb: fun(item: T))

local M = {}

---@class MoonicipalSelectOptions
---A prompt to display to the user when they select the option.
---@field prompt? string
---How to display the options in the selection UI.
---@field format? MoonicipalOptionTransformer
---Select multiple items. Setting this to `true` will make |moonicipal.select|
---return a list - even if only one item is selected.
---
---This, of course, does not work for backends that don't support multiple
---selection (like the builtin |vim.ui.select()|), and they'll still allow to
---select only one item, but if `multi` is set to `true` that one item will
---still get wrapped in a list.
---@field multi? boolean
---Show a preview for the item under the cursor.
---@field preview? fun(item: any): (string | string[])
---Add actions - keymaps that can be used to finalize the selection instead of
---Enter. When such a key is used, its string is returned as the second return
---value.
---
---The syntax for special keys is always Vim's syntax (e.g. `<C-r>`). Even when
---the backend uses a different sytnax (e.g. fzf-lua), one should still use
---Vim's sytnax and let the interaction function do the translation. The string
---returned in the second return value will still be the exact same string
---passed to `actions` - the translation is transparent to the user.
---
---The keycodes can be passed as either list items or dictionary keys - and
---both styles can be mixed in the same table:
---```
---moonicipal.select({ ... }, {
---    actions = {
---        '<M-a>',
---        ['<M-a>'] = {},
---    },
---})
---```
---When using the second style, the value is used to configure the specific
---action (see |MoonicipalSelectActionOptions|)
---@field actions? (string[] | {[string]: MoonicipalSelectActionOptions})
M.MoonicipalSelectOptions = {}

---@class MoonicipalSelectActionOptions
---Override the `multi` field from |MoonicipalSelectOptions| only for this
---action.
---@field multi? boolean
---Instead of the chosen item(s), return the text the user wrote in the query.
---@field query? boolean
M.MoonicipalSelectActionOptions = {}

return M
