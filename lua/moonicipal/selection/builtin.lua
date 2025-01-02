local util = require'moonicipal.util'

---@param options MoonicipalSelectSource The options for the user to select from
---@param opts MoonicipalSelectOptions
return function(options, opts)
    local format_item = util.transformer_as_function(opts.format)
    local new_opts = {
        format_item = function(item)
            -- Multilines may not be supported by the backend
            return string.gsub(format_item(item), '\n', ' ')
        end
    }
    if opts.prompt then
        new_opts.prompt = opts.prompt .. '> '
    end

    local new_options
    if vim.is_callable(options) then
        new_options = util.resolve_cb_function(options)
    elseif type(options) == 'table' and not vim.islist(options) then
        new_options = vim.tbl_keys(options)
        if opts.priority then
            new_options = util.prioritized(new_options, function(key)
                return opts.priority(key, options[key])
            end)
        end
        local choice = util.resume_with(function(resumer)
            vim.ui.select(new_options, new_opts, resumer)
        end)
        if opts.multi then
            return {options[choice]}
        else
            return options[choice]
        end
    else
        new_options = options
    end
    if opts.priority then
        new_options = util.prioritized(new_options, opts.priority)
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
