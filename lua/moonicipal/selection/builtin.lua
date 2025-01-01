local util = require'moonicipal.util'

---@param options MoonicipalSelectSource The options for the user to select from
---@param opts MoonicipalSelectOptions
return function(options, opts)
    local new_opts = {
        prompt = opts.prompt,
        format_item = util.transformer_as_function(opts.format),
    }

    local new_options
    if vim.is_callable(options) then
        new_options = {}
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
    elseif type(options) == 'table' and not vim.islist(options) then
        local choice = util.resume_with(function(resumer)
            vim.ui.select(vim.tbl_keys(options), new_opts, resumer)
        end)
        if opts.multi then
            return {options[choice]}
        else
            return options[choice]
        end
    else
        new_options = options
    end

    local result = util.resume_with(function(resumer)
        vim.ui.select(new_options, new_opts, resumer)
    end)
    if opts.multi then
        return {result}
    else
        return result
    end
end
