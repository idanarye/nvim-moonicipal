M = {}

function M.defer_to_coroutine(dlg, ...)
    local args = {...}
    local co = coroutine.create(function()
        xpcall(dlg, function(error)
            local traceback = debug.traceback(error, 2)
            traceback = string.gsub(traceback, '\t', string.rep(' ', 8))
            vim.api.nvim_err_writeln(traceback)
        end, unpack(args))
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

local CTRL_V = vim.api.nvim_replace_termcodes('<C-v>', true, false, true)
local CTRL_S = vim.api.nvim_replace_termcodes('<C-s>', true, false, true)

local function get_keybind_prefix_for_running_command()
    local mode = vim.fn.mode()
    if mode == 'n' then
        return ':'
    elseif mode == 'i' then
        return '<C-o>:'
    elseif mode == 'v' or mode == 'V' or mode == CTRL_V then
        return ':<C-u>'
    elseif mode == 's' or mode == 'S' or mode == CTRL_S then
        return '<C-o>:<C-u>'
    elseif mode == 't' then
        local buf_nr = vim.api.nvim_buf_get_number(0)
        for _, chan in ipairs(vim.api.nvim_list_chans()) do
            if chan.buffer == buf_nr then
                return '<C-\\><C-o>:'
            end
        end
        return ':'
    -- TODO:
    -- elseif mode == 'R' then
    -- elseif mode == 'c' then
    -- elseif mode == 'r' then
    end
    error('Cannot fix echo from mode ' .. vim.inspect(mode))
end

function M.fix_echo()
    local co = coroutine.running()
    table.insert(resumable_threads, co)
    vim.schedule(function()
        local prefix = vim.api.nvim_replace_termcodes(get_keybind_prefix_for_running_command(), true, false, true)
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

---@alias MoonicipalOptionTransformer
---| string
---| string[]
---| fun(value:any):string

---@param transformer MoonicipalOptionTransformer
function M.transformer_as_function(transformer)
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

return M
