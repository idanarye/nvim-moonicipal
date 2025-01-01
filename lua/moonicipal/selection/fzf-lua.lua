local util = require'moonicipal.util'

local function tagged_items_register_and_fetch(formatter)
    local len = 0
    local items = {}

    local function register(item)
        local formatted = formatter(item)
        len = len + 1
        items[len] = item
        return ('%d\t%s'):format(len, formatted)
    end

    local function fetch(formatted)
        local tag = vim.gsplit(formatted, '\t', {plain = true})()
        local index = tonumber(tag)
        return items[index]
    end

    return register, fetch
end

---@param options MoonicipalSelectSource The options for the user to select from
---@param opts MoonicipalSelectOptions
return function(options, opts)
    local new_opts = {
        prompt = opts.prompt,
        fzf_opts = {
            ['--with-nth'] = '2..',
            ['--delimiter'] = '\t',
        },
    }

    if opts.multi then
        new_opts.fzf_opts['--multi'] = true
    end

    local format_item = util.transformer_as_function(opts.format)
    local register, fetch = tagged_items_register_and_fetch(format_item)

    local new_options
    if vim.is_callable(options) then
        function new_options(cb)
            util.defer_to_coroutine(function()
                options(function(value)
                    cb(register(value))
                end)
                cb()
            end)
        end
    elseif type(options) == 'table' then
        if vim.islist(options) then
            new_options = vim.tbl_map(register, options)
        else
            assert(not opts.format, 'cannot use format when the options are a table')
            new_options = vim.tbl_keys(options)
            new_opts.fzf_opts['--with-nth'] = nil
            fetch = function(key)
                return options[key]
            end
        end
    end

    if opts.preview then
        new_opts.preview = function(item)
            return opts.preview(util.default_transformer(fetch(item[1])))
        end
    end

    return util.resume_with(function(resumer)
        new_opts.actions = {
            default = function(result)
                if opts.multi then
                    resumer(vim.tbl_map(fetch, result))
                else
                    resumer(fetch(result[1]))
                end
            end,
        }

        require'fzf-lua'.fzf_exec(new_options, new_opts)
    end)
end
