local M = {}

local ABORT_KEY = {'moonicipal', 'abort'}

function M.abort(msg)
    error({[ABORT_KEY] = msg or false})
end

function M.defer_to_coroutine(dlg, ...)
    local co = coroutine.create(function(...)
        xpcall(dlg, function(err)
            if type(err) == 'table' then
                local abort_message = err[ABORT_KEY]
                if abort_message ~= nil then
                    if abort_message then
                        vim.api.nvim_err_writeln(abort_message)
                    end
                    return
                end
            end
            if type(err) ~= 'string' then
                err = vim.inspect(err)
            end
            local traceback = debug.traceback(err, 2)
            traceback = string.gsub(traceback, '\t', string.rep(' ', 8))
            vim.notify(traceback, vim.log.levels.ERROR, {
                title = 'ERROR in a "Days Without" related coroutine'
            })
        end, ...)
    end)
    coroutine.resume(co, ...)
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
    elseif mode == 'i' or mode == 'R' then
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
    elseif mode == 'c' or mode == 'r' then
        return nil
    end
    error('Cannot fix echo from mode ' .. vim.inspect(mode))
end

local function resume_threads()
    local prefix = get_keybind_prefix_for_running_command()
    if prefix == nil then
        if next(resumable_threads) ~= nil then
            vim.defer_fn(resume_threads, 100)
        end
    else
        prefix = vim.api.nvim_replace_termcodes(prefix, true, false, true)
        local keycmd = 'lua require"moonicipal.util"._resume_all_threads()\n'
        vim.api.nvim_feedkeys(prefix .. keycmd, 'ni', false)
        if next(resumable_threads) ~= nil then
            vim.defer_fn(resume_threads, 1)
        end
    end
end

function M.fix_echo()
    local co = coroutine.running()
    table.insert(resumable_threads, co)
    vim.schedule(resume_threads)
    coroutine.yield()
    vim.cmd[[echon]]  -- clear the command line
end

function M.sleep(milliseconds)
    M.resume_with(function(resumer)
        vim.defer_fn(resumer, milliseconds)
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

function M.fake_scratch_buffer(set_buffer_name_to)
    local already_set_name = vim.api.nvim_buf_get_name(0)
    if already_set_name ~= '' then
        error(string.format('Cannot make %s a scratch buffer', vim.inspect(already_set_name)))
    end
    if not set_buffer_name_to then
        set_buffer_name_to = 'Moonicipal:scratch:' .. vim.loop.hrtime()
    end
    vim.cmd.file(set_buffer_name_to)
    vim.o.bufhidden = 'wipe'
    vim.api.nvim_create_autocmd('BufWriteCmd', {
        buffer = 0,
        callback = function()
        end,
    })
    vim.api.nvim_create_autocmd('BufModifiedSet', {
        buffer = 0,
        callback = function()
            vim.o.modified = false
        end,
    })
end

function M.get_buf_contents(buf_nr)
    return table.concat(vim.api.nvim_buf_get_lines(buf_nr, 0, -1, true), '\n')
end

function M.set_buf_contents(buf_nr, content)
    if type(content) == 'string' then
        content = vim.split(content, '\n')
    end
    vim.api.nvim_buf_set_lines(buf_nr, 0, -1, true, content)
end

return M
