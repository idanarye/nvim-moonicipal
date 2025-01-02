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
                title = 'ERROR in a coroutine'
            })
        end, ...)
    end)
    coroutine.resume(co, ...)
    return co
end

function M.resume_with(callback)
    local co = coroutine.running()
    local did_yield = false
    local result
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

local function resume_threads()
    local keycmd = '<Cmd>lua require"moonicipal.util"._resume_all_threads()<Cr>'
    keycmd = vim.api.nvim_replace_termcodes(keycmd, true, false, true)
    vim.api.nvim_feedkeys(keycmd, 'ni', false)
    if next(resumable_threads) ~= nil then
        vim.defer_fn(resume_threads, 1)
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

function M.default_transformer(item)
    if (getmetatable(item) or {}).__tostring then
        return tostring(item)
    elseif type(item) == 'string' then
        return item
    else
        return vim.inspect(item)
    end
end

---@param transformer MoonicipalOptionTransformer
function M.transformer_as_function(transformer)
    if transformer == nil then
        return M.default_transformer
    elseif type(transformer) == 'string' then
        return function(item)
            return item[transformer]
        end
    elseif vim.is_callable(transformer) then
        return transformer
    elseif vim.islist(transformer) then
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

---@generic T
---@param items T[]
---@param priority function(item: T): number?
---@return number[]
function M.priorities_list(items, priority)
    local priorities = {}
    local scores = {}
    for i, item in ipairs(items) do
        priorities[i] = i
        scores[i] = priority(item)
    end
    table.sort(priorities, function(a, b)
        local score_a = scores[a] or 0
        local score_b = scores[b] or 0
        if score_a < score_b then
            return false
        elseif score_b < score_a then
            return true
        else
            return a < b
        end
    end)
    return priorities
end

---@generic T
---@param items T[]
---@param indexes number[]
---@result T[]
function M.reordered_by(items, indexes)
    return vim.iter(indexes):map(function(i)
        return items[i]
    end):totable()
end

---@generic T
---@param items T[]
---@param priority function(item: T): number?
---@return T[]
function M.prioritized(items, priority)
    local priorities = M.priorities_list(items, priority)
    return M.reordered_by(items, priorities)
end

---@generic T
---@param cb_function fun(cb: fun(item: T))
---@return T[]
function M.resolve_cb_function(cb_function)
    local items = {}
    local len = 0
    cb_function(function(item)
        len = len + 1;
        items[len] = item
    end)
    return items
end

return M
