local util = require'moonicipal.util'
local selection_util = require'moonicipal.selection.util'

---@param options MoonicipalSelectSource The options for the user to select from
---@param opts MoonicipalSelectOptions
return function(options, opts)
    local new_opts = {
        fzf_opts = {
            ['--with-nth'] = '2..',
            ['--delimiter'] = '\t',
        }
    }
    new_opts.prompt = opts.prompt

    if opts.multi then
        new_opts.fzf_opts['--multi'] = true
    end

    local format_item
    if opts.format then
        format_item = util.transformer_as_function(opts.format)
    end
    if format_item == nil then
        function format_item(item)
            if type(item) == 'string' then
                return item
            else
                return vim.inspect(item)
            end
        end
    end

    local register, fetch = selection_util.tagged_items_register_and_fetch(format_item)

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
