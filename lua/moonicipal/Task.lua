---@mod MoonicipalTask API avaiable from inside a Moonicipal task
---@brief [[
---All the methods under `MoonicipalTask` can be invoked on `self` inside a
---Moonicipal task.
---@brief ]]

local util = require'moonicipal.util'

local CachedChoice = require'moonicipal.CachedChoice'

---@private
---@class MoonicipalTask
---@field task_def table
---@field context table
---@field cache table Data that will be there on the new run
local MoonicipalTask = {}

---Check if this is the entry task of the current execution.
---@return boolean
---| true if this task was invoked directly from a user command
---| false if this task was invoked as a dependency of another task
function MoonicipalTask:is_main()
    return self.context.main_task == self.task_def
end

---Use a cached result when the task is called as a dependency.
---
---When the task is invoked as a main task, the function passed as argument will
---always be called.
---
---When the task is invoked as a dependency, the function will only be called if
---the cache is empty. Otherwise, the cached result will be restored instead.
---
---Note that the cache is task-bound - using this method multiple times in the
---same task will use the same cache, even if the passed functions are
---different.
---
---    function T:dependency()
---        return self:cache_result(function()
---            return moonicipal.input { prompt = "Enter text" }
---        end)
---    end
---
---    function T:use()
---        local dependency_result = T:dependency()
---        print('You have selected', vim.inspect(dependency_result))
---    end
---@generic T
---@generic P
---@param dlg `fun(...: P): T`
---@param ... P
---@return T
function MoonicipalTask:cache_result(dlg, ...)
    local cached = self.cache[MoonicipalTask.cache_result]
    if cached ~= nil and not self:is_main() then
        return unpack(cached)
    end
    local new_result = {dlg(...)}
    self.cache[MoonicipalTask.cache_result] = new_result
    return unpack(new_result)
end

---Create a buffer, and use the result only if the buffer is still open in the
---current tab.
---
---The buffer used for the caching is the buffer Vim ends up in when the passed
---function returns, and it must be a different buffer than the one Vim was in
---when the function was called. Vim will return to the original window -
---unless the function has swiched to a new tab.
---
---See `cache_result` for other notes about the cache.
---
---    function T:log_buffer()
---        return self:cached_buf_in_tab(function()
---            vim.cmd[[new]]
---            vim.o.buftype = 'nowrite'
---            local buf_nr = vim.api.nvim_buf_get_number(0)
---            return function(text)
---                vim.api.nvim_buf_set_lines(buf_nr, -1, -1, true, { text })
---            end
---        end)
---    end
---
---    function T:log()
---        local log_buffer = T:log_buffer()
---        log_buffer(moonicipal.input())
---    end
---@generic T
---@generic P
---@param dlg `fun(...: P): T`
---@param ... P
---@return T
function MoonicipalTask:cached_buf_in_tab(dlg, ...)
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

local function run_fn_or_cmd(fn_or_cmd)
    if vim.is_callable(fn_or_cmd) then
        fn_or_cmd()
    else
        vim.cmd(fn_or_cmd)
    end
end

---@class MoonicipalCachedDataCellOptions
---Run to create a window for the data cell buffer.
---Defaults to `botright new`
---@field win? function | string
---Run only if the data cell buffer is created
---@field buf_init? function | string
---Run every time to configure the buffer
---@field buf? function | string
---Default text to put in the buffer when it is
---first created
---@field default? string | string[]
---Fail if called from a different task without setting this data cell first.
---
---If set to a string, use that string as the error message instead of the
---default generated template.
---
---Note that this is automatically turned on if `default` is not set. If this
---behavior is not desired, it can manually be set to `false`.
---@field fail_if_empty? boolean | string

---Create a data cell - a buffer where the user can put data for other tasks to
---use.
---
---When called from the main task, it'll open the buffer (if its not already
---open) and configure it. When called from another task (meaning some other
---task invokes the task that uses `self:cached_data_cell`) it'll return the
---current content of the buffer, or `nil` if the buffer does not exist.
---
---The buffer will remain in memory even if the user closes it - farther
---invocations as a main task will open it with the cached text, and calls from
---other tasks will return that text. The cached will be dropped though if the
---buffer is unloaded (e.g. by using |:bdelete|)
---
---    function T:edit_shell_command()
---        return self:cached_data_cell {
---            default = 'echo hello world',
---            buf_init = 'setfiletype bash',
---        }
---    end
---
---    function T:run_shell_command()
---        local shell_command = T:edit_shell_command() or moonicipal.abort('No command')
---        vim.cmd.new()
---        vim.cmd.terminal(shell_command)
---    end
---
---@param opts MoonicipalCachedDataCellOptions
---@return string?
function MoonicipalTask:cached_data_cell(opts)
    local cached_buffer_name = 'Moonicipal:cached_data_cell:' .. self.task_def.name

    local existing_buf_nr = nil
    if vim.fn.bufexists(cached_buffer_name) == 1 then
        existing_buf_nr = vim.fn.bufnr(cached_buffer_name)
    end

    if not self:is_main() then
        if existing_buf_nr then
            local lines = vim.api.nvim_buf_get_lines(existing_buf_nr, 0, -1, true)
            return table.concat(lines, '\n')
        elseif opts.fail_if_empty or (opts.fail_if_empty == nil and not opts.default) then
            if type(opts.fail_if_empty) == 'string' then
                util.abort(opts.fail_if_empty)
            else
                util.abort(('Missing data-cell - please run `:MC %s` to set it'):format(self.task_def.name))
            end
        elseif type(opts.default) == 'table' then
            return table.concat(opts.default, '\n')
        else
            return opts.default
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

---@class MoonicipalCachedChoiceConfiguration
---Mandatory. How to recognize the cached option.
---@field key MoonicipalOptionTransformer
---How to display the option in the selection UI.
---@field format? MoonicipalOptionTransformer
---Previewer for the option in the selection UI.
---@field preview? fun(item: any): (string | string[])
---If there is only one item in the list, choose it automatically.
---
---Note that this "choice" will not be cached, and as soon as another choice
---enters the list the user will be prompted to choose.
---
---Also note that this field is ignored when invoked as the main task.
---@field select_1? boolean

---Let the user choose from several options, and use a cached result when the
---task is called as a dependency.
---
---Unlike `cache_result`, with this method the list of options gets computed
---even when the cache is used.
---
---Use the object returned by this methoid as a function to register the
---options, and then call `:select` on it to let the user choose.
---
---    function T:choose_command()
---        local cc = self:cached_choice {
---            key = 'name',
---            format = function(cmd)
---                return ('%s [%s]'):format(cmd.name, cmd.command)
---            end,
---        }
---        cc {
---            name = 'Show the time',
---            command = 'date',
---        }
---        cc {
---            name = 'Check internet connection',
---            command = 'ping 8.8.8.8',
---        }
---        return cc:select()
---    end
---
---    function T:run_command()
---        local chosen_command = T:choose_command()
---        vim.cmd.new()
---        vim.cmd['terminal'](chosen_command.command)
---    end
---
---@param cfg? MoonicipalCachedChoiceConfiguration The configuraiton. `key` is mandatory, and `format` is probably needed.
---@return MoonicipalCachedChoice
---@see MoonicipalCachedChoice
function MoonicipalTask:cached_choice(cfg)
    if cfg == nil then
        cfg = {}
    end
    cfg.items = {}
    cfg.task = self
    return setmetatable(cfg, CachedChoice) --[[@as MoonicipalCachedChoice]]
end

return MoonicipalTask
