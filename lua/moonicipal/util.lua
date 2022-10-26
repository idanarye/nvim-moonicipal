M = {}

function M.defer_to_coroutine(dlg, ...)
    local args = {...}
    local co = coroutine.create(function()
        xpcall(dlg, function(error)
            local traceback = debug.traceback(error, 2)
            traceback = string.gsub(traceback, '\t', string.rep(' ', 8))
            vim.api.nvim_err_writeln(traceback)
        end, unpack)
    end)
    coroutine.resume(co)
    return co
end

function M.resume_with(callback)
    local co = coroutine.running()
    local did_yield = false
    local result = nil
    callback(function(...)
        if did_yield then
            coroutine.resume(co, ...)
        else
            did_yield = true
            result = {...}
        end
    end)
    if did_yield then
        return unpack(result)
    else
        did_yield = true
        return coroutine.yield()
    end
end

local resumable_threads = {}

function M._resume_all_threads()
    while true do
        local thread = table.remove(resumable_threads)
        if not thread then
            return
        end
        coroutine.resume(thread)
    end
end

local ECHO_PREFIXES_BY_MODE = {
    n = ':';
    i = '<C-o>:';
    v = ':<C-u>';
    s = '<C-o>:<C-u>';
    t = '<C-\\><C-o>:';
    -- TODO:
    -- R =
    -- c =
    -- r =
    -- ! =
}
ECHO_PREFIXES_BY_MODE[vim.api.nvim_replace_termcodes('<C-v>', true, false, true)] = ECHO_PREFIXES_BY_MODE.v
ECHO_PREFIXES_BY_MODE[vim.api.nvim_replace_termcodes('<C-s>', true, false, true)] = ECHO_PREFIXES_BY_MODE.s

function M.fix_echo()
    local co = coroutine.running()
    table.insert(resumable_threads, co)
    vim.schedule(function()
        local prefix = vim.api.nvim_replace_termcodes(
            ECHO_PREFIXES_BY_MODE[vim.fn.mode():lower()],
            true, false, true)
        local keycmd = 'lua require"moonicipal/util"._resume_all_threads()\n'
        vim.api.nvim_feedkeys(prefix .. keycmd, 'n', false)
    end)
    coroutine.yield()
    vim.cmd[[echon]]  -- clear the command line
end

function M.sleep(timeout)
    M.resume_with(function(resumer)
        vim.defer_fn(resumer, timeout)
    end)
end

return M
