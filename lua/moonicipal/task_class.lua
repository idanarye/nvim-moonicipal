---@class TaskClass
---@field task_def table
---@field context table
---@field cache table Data that will be there on the new run
local TaskClass = {}

-- Run another task if it hasn't been run before this execution.
---@generic T
---@param task fun(self: any): T
---@return T
function TaskClass:dep(task)
    return self.context:dep(task)
end

--- Check if this is the entry task of the current execution.
---@return
---| true # if this task was invoked directly from a user command
---| false # if this task was invoked as a dependency of another task
function TaskClass:is_main()
    return self.context.main_task == self.task_def
end

-- Use a cached result when the task is called as a dependency.
--
-- When the task is invoked as a main task, the function passed as argument will
-- always be called.
--
-- When the task is invoked as a dependency, the function will only be called if
-- the cache is empty. Otherwise, the cached result will be restored instead.
--
-- Note that the cache is task-bound - using this method multiple times in the
-- same task will use the same cache, even if the passed functions are
-- different.
--
--    function T:dependency()
--        return self:cache_result(function()
--            return moonicipal.input { prompt = "Enter text: " }
--        end)
--    end
--
--    function T:use()
--        local dependency_result = self:dep(T.dependency)
--        print('You have selected', vim.inspect(dependency_result))
--    end
---@generic T
---@generic P
---@param dlg fun(...: P): T
---@param ... P
---@return T
function TaskClass:cache_result(dlg, ...)
    local cached = self.cache[TaskClass.cache_result]
    if cached ~= nil and not self:is_main() then
        return unpack(cached)
    end
    local new_result = {dlg(...)}
    self.cache[TaskClass.cache_result] = new_result
    return unpack(new_result)
end

-- Create a buffer, and use the result only if the buffer is still open in the
-- current tab.
--
-- The buffer used for the caching is the buffer Vim ends up in when the passed
-- function returns, and it must be a different buffer than the one Vim was in
-- when the function was called. Vim will return to the original window -
-- unless the function has swiched to a new tab.
--
-- See `cache_result` for other notes about the cache.
--
--    function T:log_buffer()
--        return self:cached_buf_in_tab(function()
--            vim.cmd[[new]]
--            vim.o.buftype = 'nowrite'
--            local buf_nr = vim.api.nvim_buf_get_number(0)
--            return function(text)
--                vim.api.nvim_buf_set_lines(buf_nr, -1, -1, true, { text })
--            end
--        end)
--    end
--
--    function T:log()
--        local log_buffer = self:dep(T.log_buffer)
--        log_buffer(moonicipal.input())
--    end
---@generic T
---@generic P
---@param dlg fun(...: P): T
---@param ... P
---@return T
function TaskClass:cached_buf_in_tab(dlg, ...)
    local cache_key = 'Moonicipal:cached_buf_in_tab:' .. self.task_def.name
    for _, win_nr in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf_nr = vim.api.nvim_win_get_buf(win_nr)
        local has_cache, cache = pcall(vim.api.nvim_buf_get_var, buf_nr, cache_key)
        if has_cache then
            return unpack(cache)
        end
    end

    local orig_window = vim.fn.win_getid()
    local orig_buffer = vim.api.nvim_win_get_buf(0)
    local result = {dlg(...)}
    local new_buffer = vim.api.nvim_win_get_buf(0)
    assert(orig_buffer ~= new_buffer, '`cached_buf_in_tab` function did not create a new buffer')
    local orig_window_tab = vim.fn.win_id2tabwin(orig_window)[1]
    local current_tab = vim.fn.tabpagenr()
    if current_tab == orig_window_tab then
        vim.fn.win_gotoid(orig_window)
    end
    vim.b[cache_key] = result
    return unpack(result)
end

---@alias OptionTransformer
---| string
---| string[]
---| fun(value:any):string

---@param transformer OptionTransformer
local function transformer_as_function(transformer)
    if type(transformer) == 'string' then
        return function(item)
            return item[transformer]
        end
    elseif vim.is_callable(transformer) then
        return transformer
    elseif vim.tbl_islist(transformer) then
        return function(item)
            return vim.tbl_get(item, unpack(transformer --[[@as string[] ]]))
        end
    else
        error('Illegal format ' .. vim.inspect(transformer))
    end
end

---@class CachedChoiceConfiguration
---@field key OptionTransformer Mandatory. How to recognize the cached option.
---@field format OptionTransformer How to display the option in the selection UI.

---@class CachedChoice: CachedChoiceConfiguration
---@operator call(number): string
local CachedChoice = {}
CachedChoice.__index = CachedChoice

function CachedChoice:__call(option)
    table.insert(self, option)
end

-- Let the user choose from several options, and use a cached result when the
-- task is called as a dependency.
--
-- Unlike `cache_result`, with this method the list of options gets computed
-- even when the cache is used.
--
-- Use the object returned by this methoid as a function to register the
-- options, and then call `:select` on it to let the user choose.
--
--    function T:choose_command()
--        local cc = self:cached_choice {
--            key = 'name',
--            format = function(cmd)
--                return ('%s [%s]'):format(cmd.name, cmd.command)
--            end,
--        }
--        cc {
--            name = 'Show the time',
--            command = 'date',
--        }
--        cc {
--            name = 'Check internet connection',
--            command = 'ping 8.8.8.8',
--        }
--        return cc:select()
--    end
--
--    function T:run_command()
--        local chosen_command = self:dep(T.choose_command)
--        vim.cmd.new()
--        vim.cmd['terminal'](chosen_command.command)
--    end
--
---@param cfg? CachedChoiceConfiguration The configuraiton. `key` is mandatory, and `format` is probably needed.
---@return CachedChoice
function TaskClass:cached_choice(cfg)
    if cfg == nil then
        cfg = {}
    end
    cfg.task = self
    return setmetatable(cfg, CachedChoice) --[[@as CachedChoice]]
end

--- Let the user choose using `moonicipal.selected`.
function CachedChoice:select()
    assert(self.key, '`cached_choice` used without setting a key')
    local key_fn = transformer_as_function(self.key)

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

    local options = {}
    if self.format then
        options.format_item = transformer_as_function(self.format)
    end
    local chosen = require'moonicipal'.select(self, options)
    self.task.cache[CachedChoice] = key_fn(chosen)
    return chosen
end


return TaskClass
