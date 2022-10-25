M = {}

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

function M.fix_echo()
    local co = coroutine.running()
    table.insert(resumable_threads, co)
    local keycmd = ':lua require"moonicipal/util"._resume_all_threads()\n'
    vim.schedule(function()
        vim.api.nvim_feedkeys(keycmd, 'n', false)
    end)
    coroutine.yield()
end

return M
