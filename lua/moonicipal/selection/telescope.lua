local util = require'moonicipal.util'

---@param options MoonicipalSelectSource The options for the user to select from
---@param opts MoonicipalSelectOptions
return function(options, opts)
    -- TODO: deal with multi

    local format_item
    if opts.format then
        format_item = util.transformer_as_function(opts.format)
    else
        format_item = vim.inspect
    end
    local function entry_maker(item)
        local formatted = format_item(item)
        return {
            value = item,
            display = formatted,
            ordinal = formatted,
        }
    end

    local finder
    if vim.is_callable(options) then
        -- TODO: make this lazy
        local items = {}
        local len = 0
        options(function(item)
            len = len + 1;
            items[len] = item
        end)
        finder = require'telescope.finders'.new_table {
            results = items,
            entry_maker = entry_maker,
        }
    elseif type(options) == 'table' then
        if vim.islist(options) then
            finder = require'telescope.finders'.new_table {
                results = options,
                entry_maker = entry_maker,
            }
        else
            assert(not opts.format, 'cannot use format when the options are a table')
            finder = require'telescope.finders'.new_table {
                results = vim.tbl_keys(options),
                entry_maker = function(key)
                    return {
                        value = options[key],
                        display = key,
                        ordinal = key,
                    }
                end,
            }
        end
    end

    return util.resume_with(function(resumer)
        require'telescope.pickers'.new({}, {
            finder = finder,
            attach_mappings = function()
                require'telescope.actions'.select_default:replace(function(bufnr)
                    if opts.multi then
                        local picker = require'telescope.actions.state'.get_current_picker(bufnr)
                        local chosens = picker:get_multi_selection()
                        --vim.notify(vim.inspect {
                            --chosens = chosens,
                            --is_not_nil = next(chosens) ~= nil,
                        --})
                        if next(chosens) ~= nil then
                            resumer(vim.tbl_map(function(item)
                                return item.value
                            end, chosens))
                            require'telescope.actions'.close(bufnr)
                            return
                        end
                    end
                    local chosen = require'telescope.actions.state'.get_selected_entry()
                    require'telescope.actions'.close(bufnr)
                    if opts.multi then
                        resumer({chosen.value})
                    else
                        resumer(chosen.value)
                    end
                end)
                return true
            end,
        }):find()
    end)
end
