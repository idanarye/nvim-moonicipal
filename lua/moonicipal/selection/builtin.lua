local util = require'moonicipal.util'

---@param options any[] The options for the user to select from
---@param opts MoonicipalSelectOptions
return function(options, opts)
    local new_opts = {}
    new_opts.prompt = opts.prompt
    if opts.format then
        new_opts.format_item = util.transformer_as_function(opts.format)
    end
    if new_opts.format_item == nil then
        function new_opts.format_item(item)
            if type(item) == 'string' then
                return item
            else
                return vim.inspect(item)
            end
        end
    end

    if vim.is_callable(options) then
        local new_options = {}
        local new_options_len = 0
        util.resume_with(function(resumer)
            util.defer_to_coroutine(function()
                options(function(option)
                    new_options_len = new_options_len + 1
                    new_options[new_options_len] = option
                end)
                resumer()
            end)
        end)
        options = new_options
    elseif type(options) == 'table' and not vim.islist(options) then
        local choice = util.resume_with(function(resumer)
            vim.ui.select(vim.tbl_keys(options), new_opts, resumer)
        end)
        return options[choice]
    end

    return util.resume_with(function(resumer)
        vim.ui.select(options, new_opts, resumer)
    end)
end
