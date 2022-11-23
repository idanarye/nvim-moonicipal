local util = require'moonicipal/util'
local execution_context = require'moonicipal/execution_context'
local MunicipalTaskOutside = require'moonicipal/task_class_outside'

local M = {}

---@class Decoration
---@field alias string | string[] Allow invoking the task by some other name. Will not show in the tasks list.

---@class Populator
local P = {}
function M.populator()
    if type(M.tasks) ~= 'table' then
        error('populator called not from tasks file')
    end
    return setmetatable({
        tasks = M.tasks,
        task_names_by_order = M.task_names_by_order,
    }, P)
end

function P:__call(decoration)
    if rawget(self, 'decoration') then
        error('Only one decoration allowed per task', 2)
    end
    rawset(self, 'decoration', decoration)
end

function P:__index(task_name)
    return rawget(self, 'tasks')[task_name]
end

local function as_iterator(value)
    if value == nil then
        return function()
            -- Do nothing - empty iteration
        end
    elseif vim.tbl_islist(value) then
        return ipairs(value)
    else
        local need_to_send = true
        return function()
            if need_to_send then
                need_to_send = false
                return 1, value
            end
        end
    end
end

function P:__newindex(task_name, task_run_function)
    vim.validate {
        {task_run_function, 'function'};
    }
    local decoration = rawget(self, 'decoration') or {}
    rawset(self, 'decoration', nil)
    local tasks = rawget(self, 'tasks')
    local task_def = setmetatable({
        name = task_name,
        run = task_run_function,
    }, MunicipalTaskOutside)
    table.insert(rawget(self, 'task_names_by_order'), task_name)
    tasks[task_name] = task_def
    for _, alias in as_iterator(decoration.alias) do
        tasks[alias] = task_def
    end
end

local T = {}
function M.load(path)
    local tasks = {}
    local task_names_by_order = {}
    M.tasks = tasks
    M.task_names_by_order = task_names_by_order
    dofile(path)
    M.tasks = nil
    M.task_names_by_order = nil
    return vim.tbl_extend('error', T, {
        tasks = tasks,
        task_names_by_order = task_names_by_order,
    })
end

local selection_lru = {}

function T:select_and_invoke()
    local task_names = vim.fn.copy(self.task_names_by_order)
    local order = vim.tbl_add_reverse_lookup(vim.fn.copy(selection_lru))
    task_names = vim.fn.sort(task_names, function(a, b)
        return (order[b] or 0) - (order[a] or 0)
    end)
    util.defer_to_coroutine(function()
        local task_name = util.resume_with(function(resumer)
            vim.ui.select(task_names, {
                prompt = 'Choose task to run: ';
            }, resumer)
        end)
        if not task_name then
            return
        end
        local old_index = 1 + vim.fn.index(selection_lru, task_name)
        if 0 < old_index then
            table.remove(selection_lru, old_index)
        end
        table.insert(selection_lru, task_name)
        local max_length = require'moonicipal/settings'.tasks_selection_lru_size
        if 0 <= max_length then
            while max_length < #selection_lru do
                table.remove(selection_lru, 1)
            end
        end
        util.fix_echo()
        self:invoke(task_name)
    end)
end

function T:get_task(task_name)
    --TODO: check that it's really a task, and not just any table?
    if type(task_name) == 'table' then
        return task_name
    end
    local task = self.tasks[task_name]
    if task == nil then
        error('No such task ' .. vim.inspect(task_name))
    end
    return task
end

function T:invoke(task)
    task = self:get_task(task)
    util.defer_to_coroutine(function()
        local context = execution_context(self)
        context.main_task = task
        context:run(task)
    end)
end

function M.open_for_edit(edit_cmd, file_name, task_name)
    vim.cmd(edit_cmd .. ' ' .. file_name)
    local is_brand_new = vim.api.nvim_buf_line_count(0) == 1 and vim.fn.filereadable(file_name) == 0 and vim.api.nvim_buf_get_lines(0, 0, 1, true)[1] == ""
    if is_brand_new then
        vim.api.nvim_buf_set_lines(0, 0, 1, true, {
            [[local moonicipal = require'moonicipal']],
            [[local T = moonicipal.tasks_file()]],
        })
    end

    if task_name ~= nil then
        local task = nil
        if not is_brand_new then
            task = M.load(file_name).tasks[task_name]
        end
        if task == nil then
            local header = 'function T:' .. task_name .. '()'
            if loadstring(header .. '\nend') == nil then
                header = 'T[' .. vim.inspect(task_name) .. '] = function(self)'
            end
            vim.api.nvim_buf_set_lines(0, -1, -1, true, {
                '',
                header,
                '    ',
                'end',
            })
            local last_line = vim.api.nvim_buf_line_count(0)
            vim.api.nvim_win_set_cursor(0, {last_line, 0})
            vim.api.nvim_win_set_cursor(0, {last_line - 1, 0})
            vim.cmd[[startinsert!]]
        else
            if type(task.run) == 'function' then
                local task_info = debug.getinfo(task.run)
                -- Go to last line then first, to ensure they are all (or at least most) visible.
                vim.api.nvim_win_set_cursor(0, {task_info.lastlinedefined, 0})
                vim.api.nvim_win_set_cursor(0, {task_info.linedefined, 0})
            end
        end
    end
end

return M
