local util = require'moonicipal/util'

---@class MoonicipalTaskClassInside
---@field task_def table
---@field context table
---@field cache table Data that will be there on the new run
local MoonicipalTaskClassInside = {}

--- Check if this is the entry task of the current execution.
---@return
---| true # if this task was invoked directly from a user command
---| false # if this task was invoked as a dependency of another task
function MoonicipalTaskClassInside:is_main()
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
--        local dependency_result = T:dependency()
--        print('You have selected', vim.inspect(dependency_result))
--    end
---@generic T
---@generic P
---@param dlg fun(...: P): T
---@param ... P
---@return T
function MoonicipalTaskClassInside:cache_result(dlg, ...)
    local cached = self.cache[MoonicipalTaskClassInside.cache_result]
    if cached ~= nil and not self:is_main() then
        return unpack(cached)
    end
    local new_result = {dlg(...)}
    self.cache[MoonicipalTaskClassInside.cache_result] = new_result
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
--        local log_buffer = T:log_buffer()
--        log_buffer(moonicipal.input())
--    end
---@generic T
---@generic P
---@param dlg fun(...: P): T
---@param ... P
---@return T
function MoonicipalTaskClassInside:cached_buf_in_tab(dlg, ...)
    local cache_key = 'Moonicipal:cached_buf_in_tab:' .. self.task_def.name
    for _, win_nr in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf_nr = vim.api.nvim_win_get_buf(win_nr)
        local has_cache, cache = pcall(vim.api.nvim_buf_get_var, buf_nr, cache_key)
        if has_cache then
            return cache()
        end
    end

    local orig_window = vim.fn.win_getid()
    local orig_buffer = vim.api.nvim_win_get_buf(0)
    local result = {dlg(...)}
    local new_buffer = vim.api.nvim_win_get_buf(0)
    assert(orig_buffer ~= new_buffer, '`cached_buf_in_tab` function did not create a new buffer')
    vim.b[cache_key] = function()
        return unpack(result)
    end
    local orig_window_tab = vim.fn.win_id2tabwin(orig_window)[1]
    local current_tab = vim.fn.tabpagenr()
    if current_tab == orig_window_tab then
        vim.fn.win_gotoid(orig_window)
    end
    return unpack(result)
end

---@class CachedChoiceConfiguration
---@field key MoonicipalOptionTransformer Mandatory. How to recognize the cached option.
---@field format MoonicipalOptionTransformer How to display the option in the selection UI.

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
--        local chosen_command = T:choose_command()
--        vim.cmd.new()
--        vim.cmd['terminal'](chosen_command.command)
--    end
--
---@param cfg? CachedChoiceConfiguration The configuraiton. `key` is mandatory, and `format` is probably needed.
---@return CachedChoice
function MoonicipalTaskClassInside:cached_choice(cfg)
    if cfg == nil then
        cfg = {}
    end
    cfg.task = self
    return setmetatable(cfg, CachedChoice) --[[@as CachedChoice]]
end

--- Let the user choose using `moonicipal.selected`.
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

local function run_fn_or_cmd(fn_or_cmd)
    if vim.is_callable(fn_or_cmd) then
        fn_or_cmd()
    else
        vim.cmd(fn_or_cmd)
    end
end

---@class MoonicipalCachedDataCellOptions
---@field win? function | string Run to create a window for the data cell buffer. Defaults to `botright new`
---@field buf_init? function | string Run only if the data cell buffer is created
---@field buf? function | string Run every time to configure the buffer
---@field default? string | string[] yup

---@param opts MoonicipalCachedDataCellOptions
---@return string?
function MoonicipalTaskClassInside:cached_data_cell(opts)
    local cached_buffer_name = 'Moonicipal:cached_data_cell:' .. self.task_def.name

    local existing_buf_nr = nil
    if vim.fn.bufexists(cached_buffer_name) == 1 then
        existing_buf_nr = vim.fn.bufnr(cached_buffer_name)
    end

    if not self:is_main() then
        if existing_buf_nr then
            local lines = vim.api.nvim_buf_get_lines(existing_buf_nr, 0, -1, true)
            return table.concat(lines, '\n')
        else
            return
        end
    end

    if existing_buf_nr then
        local open_in_win = nil
        for _, win_id in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.api.nvim_win_get_buf(win_id) == existing_buf_nr then
                open_in_win = win_id
                break
            end
        end
        if open_in_win then
            vim.fn.win_gotoid(open_in_win)
        else
            run_fn_or_cmd(opts.win or 'botright new')
            vim.cmd.buffer(cached_buffer_name)
        end
    else
        run_fn_or_cmd(opts.win or 'botright new')
        util.fake_scratch_buffer(cached_buffer_name)
        vim.o.bufhidden = 'hide'
        if opts.default then
            util.set_buf_contents(0, opts.default)
        end
        if opts.buf_init then
            run_fn_or_cmd(opts.buf_init)
        end
    end

    if opts.buf then
        run_fn_or_cmd(opts.buf)
    end
end

return MoonicipalTaskClassInside
