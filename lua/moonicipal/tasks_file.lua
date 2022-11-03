local util = require'moonicipal/util'
local RegularTask =require'moonicipal/regular_task'
local execution_context = require('moonicipal/execution_context')
local cache = require('moonicipal/cache')

local M = {}

---@class Populator
local P = {}
function M.populator()
    return setmetatable({}, P)
end

function P:__call(prepare)
    vim.validate {
        prepare = {prepare, 'table'};
    }
    rawset(self, 'prepare', prepare)
end

function P:__index()
    error('Cannot get stuff from the tasks file populator')
end

function P:__newindex(task_name, task_def)
    vim.validate {
        prepare = {task_def, 'function'};
    }
    if type(task_def) == 'function' then
        local prepare = rawget(self, 'prepare') or {}
        rawset(self, 'prepare', nil)
        if not prepare.task_type then
            prepare.task_type = RegularTask
        end
        prepare.name = task_name
        prepare.run = task_def
        M.current[task_name] = prepare
    end
end

local T = {}
function M.load(path)
    local tasks = {}
    M.current = tasks
    loadfile(path)()
    M.current = nil
    return vim.tbl_extend('error', T, {
        tasks = tasks;
    })
end

function T:select_and_invoke()
    util.defer_to_coroutine(function()
        local task_name = util.resume_with(function(resumer)
            vim.ui.select(vim.tbl_keys(self.tasks), {
                prompt = 'Choose task to run: ';
            }, resumer)
        end)
        if not task_name then
            return
        end
        util.fix_echo()
        self:invoke(task_name)
    end)
end

function T:get_task(task_name)
    local task = self.tasks[task_name]
    if task == nil then
        error('No such task ' .. vim.inspect(task_name))
    end
    return task
end

function T:invoke(task_name, ...)
    local task = self:get_task(task_name)
    local task_args = {...}
    util.defer_to_coroutine(function()
        local context = execution_context(self)
        cache.cycle(self)
        context.main_task = task
        task.task_type:run(context, task, task_args)
    end)
end

function M.open_for_edit(edit_cmd, file_name, task_name)
    vim.cmd(edit_cmd .. ' ' .. file_name)
    if (vim.api.nvim_buf_line_count(0) == 1
        and vim.fn.filereadable(file_name) == 0
        and vim.api.nvim_buf_get_lines(0, 0, 1, true)[1] == ""
        ) then
        vim.api.nvim_buf_set_lines(0, 0, 1, true, {
            [[local moonicipal = require'moonicipal']],
            [[local T = moonicipal.tasks_file()]],
        })
    end

    if task_name ~= nil then
        local task = M.load(file_name).tasks[task_name]
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
