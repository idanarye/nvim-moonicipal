local util = require'moonicipal.util'
local execution_context = require'moonicipal.execution_context'
local MoonicipalRegistrar = require'moonicipal.Registrar'

local M = {}

function M.get_file_name()
    return require'moonicipal.settings'.file_prefix .. '.moonicipal.lua'
end

function M.registrar()
    if type(M.tasks) ~= 'table' then
        error('registrar called not from tasks file')
    end
    return setmetatable({
        tasks = M.tasks,
        task_names_by_order = M.task_names_by_order,
    }, MoonicipalRegistrar)
end

function M.include(namespace, lib)
    if lib ~= nil then
        vim.validate {
            namespace = {namespace, 'string'},
            lib = {lib, {'table', 'function'}},
        }
        if M.libraries[namespace] then
            error('Namespace "' .. namespace .. '" is already in use')
        end
        M.libraries[namespace] = lib
    else
        lib = namespace
        vim.validate {
            lib = {lib, {'table', 'function'}},
        }
        if rawget(lib, 'tasks') then
            table.insert(M.libraries, lib)
        else
            vim.list_extend(M.libraries, lib)
        end
    end
    return lib
end

local T = {}

function M.load(path)
    local tasks = {}
    local task_names_by_order = {}
    local libraries = {}
    M.tasks = tasks
    M.task_names_by_order = task_names_by_order
    M.libraries = libraries
    dofile(path)
    M.tasks = nil
    M.task_names_by_order = nil
    return vim.tbl_extend('error', T, {
        tasks = tasks,
        task_names_by_order = task_names_by_order,
        libraries = libraries,
    })
end

local selection_lru = {}

function T:all_task_names()
    local task_names = vim.fn.copy(self.task_names_by_order)
    for _, lib in ipairs(self.libraries) do
        vim.list_extend(task_names, lib.task_names_by_order)
    end
    for namespace, lib in pairs(self.libraries) do
        if type(namespace) == 'string' then
            for _, task_name in ipairs(lib.task_names_by_order) do
                table.insert(task_names, namespace .. '::' .. task_name)
            end
        end
    end

    local deduped = {}
    local i = 0
    local seen = {}
    for _, task_name in ipairs(task_names) do
        if not seen[task_name] then
            seen[task_name] = true
            i = i + 1
            deduped[i] = task_name
        end
    end
    return deduped
end

function T:select_and_invoke()
    local order = {}
    for k, v in pairs(selection_lru) do
        order[v] = k
    end
    local task_names = vim.fn.sort(self:all_task_names(), function(a, b)
        return (order[b] or 0) - (order[a] or 0)
    end)
    util.defer_to_coroutine(function()
        local task_actions = require'moonicipal.settings'.task_actions
        local actions = {}
        if task_actions.add then
            actions[task_actions.add] = {query = true}
        end
        if task_actions.edit then
            actions[task_actions.edit] = {}
        end
        local task_name, action = require'moonicipal'.select(task_names, {
            prompt = 'Choose task to run',
            actions = actions,
        })
        if not task_name then
            return
        end
        --NOTE: `add` and `edit` do the same thing, the only difference is that
        --`add` uses the query and `edit` the selection.
        if action == task_actions.add then
            if task_name == '' then
                vim.notify('Cannot add an empty action')
                return
            end
            M.open_for_edit('edit', M.get_file_name(), task_name)
            return
        elseif action == task_actions.edit then
            M.open_for_edit('edit', M.get_file_name(), task_name)
            return
        end
        local old_index = 1 + vim.fn.index(selection_lru, task_name)
        if 0 < old_index then
            table.remove(selection_lru, old_index)
        end
        table.insert(selection_lru, task_name)
        local max_length = require'moonicipal.settings'.tasks_selection_lru_size
        if 0 <= max_length then
            while max_length < #selection_lru do
                table.remove(selection_lru, 1)
            end
        end
        util.fix_echo()
        self:invoke(task_name)
    end)
end

function T:get_task_by_name(task_name)
    -- Get a task from the tasks file
    if self.tasks[task_name] then
        return self.tasks[task_name]
    end

    -- Get a task from the tasks library
    for _, library in ipairs(self.libraries) do
        if library.tasks[task_name] then
            return library.tasks[task_name]
        end
    end

    -- Get a namespaced task
    local namespace, rest = task_name:match('^([%w_-]+)::(.*)$')
    if namespace then
        local library = self.libraries[namespace]
        if library then
            return library[rest]
        end
    end

    return nil
end

function T:invoke(task_name)
    local task = self:get_task_by_name(task_name)
    if not task then
        vim.api.nvim_err_writeln('No such task ' .. vim.inspect(task_name))
        return
    end
    return util.defer_to_coroutine(function()
        local context = execution_context()
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
            local tasks_file = M.load(file_name)
            task = tasks_file:get_task_by_name(task_name)
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
                if vim.startswith(task_info.source, '@') then
                    vim.cmd.edit(task_info.source:sub(2))
                    -- Go to last line then first, to ensure they are all (or at least most) visible.
                    vim.api.nvim_win_set_cursor(0, {task_info.lastlinedefined, 0})
                    vim.api.nvim_win_set_cursor(0, {task_info.linedefined, 0})
                end
            end
        end
    end
end

return M
