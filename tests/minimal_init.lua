vim.o.shada = ''

vim.opt.runtimepath:append { '.' }
vim.opt.runtimepath:append { '../plenary.nvim' }

require'moonicipal'.setup {
    file_prefix = '.testing',
}

local MOONICIPAL_TASKS_FILE_NAME = '.testing.moonicipal.lua'

function BeforeTestCleanup()
    OUTPUT = nil
    -- Ensure single window
    local wins = vim.api.nvim_list_wins()
    vim.cmd.new()
    for _, winnr in ipairs(wins) do
        vim.api.nvim_win_close(winnr, true)
    end
    -- Remove tasks file
    WaitFor(1, function()
        return os.remove(MOONICIPAL_TASKS_FILE_NAME) == nil
    end, 1)
end

function SetTasksFile(content)
    vim.fn.writefile(vim.split(content, '\n'), MOONICIPAL_TASKS_FILE_NAME)
end

function SetTasksFileTasks(content)
    SetTasksFile(table.concat({
        'local moonicipal = require"moonicipal"',
        'local T = moonicipal.tasks_file()',
        '',
        content,
    }, '\n'))
end

function Sleep(duration)
    local co = coroutine.running()
    vim.defer_fn(function()
        coroutine.resume(co)
    end, duration)
    coroutine.yield()
end

function WaitFor(timeout_secs, pred, sleep_ms)
    local init_time = vim.loop.uptime()
    local last_time = init_time + timeout_secs
    while true do
        local iteration_time = vim.loop.uptime()
        local result = {pred()}
        if result[1] then
            return unpack(result)
        end
        if last_time < iteration_time then
            error('Took too long (' .. (iteration_time - init_time) .. ' seconds)')
        end
        Sleep(sleep_ms or 10)
    end
end

function Override(tbl, overrides)
    return function()
        local originals = {}
        for key, value in pairs(overrides) do
            originals[key] = {rawget(tbl, key)}
            rawset(tbl, key, value)
        end
        coroutine.yield()
        for key, value in pairs(originals) do
            rawset(tbl, key, value[1])
        end
    end
end
