local util = require'moonicipal.util'

---@param options MoonicipalSelectSource The options for the user to select from
---@param opts MoonicipalSelectOptions
return function(options, opts)
    local format_item = util.transformer_as_function(opts.format)
    local function entry_maker(item)
        local formatted = format_item(item)
        return {
            value = item,
            display = string.gsub(formatted, '\n', ' '),
            ordinal = formatted,
        }
    end

    local finder
    local preselect_index = opts.preselect
    if vim.is_callable(options) then
        -- TODO: make this lazy
        options = util.resolve_cb_function(options)
    end
    if type(options) == 'table' then
        if vim.islist(options) then
            local new_options = options
            if opts.priority then
                local priorities = util.priorities_list(new_options, opts.priority)
                new_options = util.reordered_by(new_options, priorities)
                preselect_index = vim.iter(ipairs(priorities)):find(function(_, i)
                    return i == preselect_index
                end)
            end
            finder = require'telescope.finders'.new_table {
                results = new_options,
                entry_maker = entry_maker,
            }
        else
            assert(not opts.format, 'cannot use format when the options are a table')
            local options_keys = vim.tbl_keys(options)
            options_keys = util.prioritized(options_keys, function(key)
                return opts.priority(key, options[key])
            end)
            preselect_index = vim.iter(ipairs(options_keys)):find(function(_, key)
                return preselect_index == key
            end)
            finder = require'telescope.finders'.new_table {
                results = options_keys,
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

    local function normalize_lines_list(source)
        if source == nil then
            return {}
        elseif (getmetatable(source) or {}).__tostring then
            return vim.split(tostring(source), '\n', {plain = true})
        elseif type(source) == 'string' then
            return vim.split(source, '\n', {plain = true})
        elseif vim.islist(source) and vim.iter(source):all(function(entry)
            return type(entry) == 'string'
        end)
        then
            return vim.iter(source):map(function(entry)
                return vim.split(entry, '\n', {plain = true})
            end)
            :flatten()
            :totable()
        else
            return vim.split(vim.inspect(source), '\n', {plain = true})
        end
    end

    local previewer
    if opts.preview then
        previewer = require'telescope.previewers'.new_buffer_previewer {
            define_preview = function(self, item)
                local preview = normalize_lines_list(opts.preview(item.value))
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, true, preview)
            end,
        }
    end

    return util.resume_with(function(resumer)
        require'telescope.pickers'.new({}, {
            prompt_title = opts.prompt,
            finder = finder,
            sorter = require'telescope.config'.values.generic_sorter{},
            previewer = previewer,
            default_selection_index = preselect_index,
            attach_mappings = function(_, map_action)
                local function gen_action(return_marker, action_opts)
                    action_opts = vim.tbl_extend('keep', action_opts, {multi = opts.multi})
                    return function(bufnr)
                        if action_opts.query then
                            local query_text = require'telescope.actions.state'.get_current_line()
                            require'telescope.actions'.close(bufnr)
                            resumer(query_text, return_marker)
                            return
                        end

                        if action_opts.multi then
                            local picker = require'telescope.actions.state'.get_current_picker(bufnr)
                            local chosens = picker:get_multi_selection()
                            if next(chosens) ~= nil then
                                resumer(vim.tbl_map(function(item)
                                    return item.value
                                end, chosens))
                                require'telescope.actions'.close(bufnr)
                                return
                            end
                        end
                        local chosen = require'telescope.actions.state'.get_selected_entry() or {}
                        require'telescope.actions'.close(bufnr)
                        if action_opts.multi then
                            resumer({chosen.value}, return_marker)
                        else
                            resumer(chosen.value, return_marker)
                        end
                    end
                end
                require'telescope.actions'.select_default:replace(gen_action(nil, {}))

                for k, v in pairs(opts.actions or {}) do
                    if type(k) == 'number' then
                        map_action({'n', 'i'}, v, gen_action(v, {}))
                    else
                        map_action({'n', 'i'}, k, gen_action(k, v))
                    end
                end

                return true
            end,
        }):find()
    end)
end
