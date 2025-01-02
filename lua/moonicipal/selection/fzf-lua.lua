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
        if formatted == nil then
            return nil
        end
        local tag = vim.gsplit(formatted, '\t', {plain = true})()
        local index = tonumber(tag)
        return items[index]
    end

    return register, fetch
end

local MODIFIER_MAP = {
    s = 'shift',
    c = 'ctrl',
    m = 'alt',
    a = 'alt',
}

local SPECIALS_MAP = {
    ['bs'] = 'bs',
    ['tab']	= 'tab',
    ['cr'] = 'enter',
    ['return'] = 'enter',
    ['enter'] = 'enter',
    ['esc']	= 'esc',
    ['space'] = 'space',
    ['lt'] = '<',
    ['bslash'] = '\\',
    ['bar']	= '|',
    ['del']	= 'del',
    ['up'] = 'up',
    ['down'] = 'down',
    ['left'] = 'left',
    ['right'] = 'right',
    ['insert'] = 'insert',
    ['home'] = 'home',
    ['end']	= 'end',
    ['pageup'] = 'page-up',
    ['pagedown'] = 'page-down',
}

local function keycode_to_fzf(keycode)
    local _, _, special = keycode:find[=[^<(.*)>$]=]
    if special == nil then
        return keycode
    end
    local _, _, modifier, after_modifier = special:find[=[^([casmCASM])-(.*)$]=]
    if modifier == 's' or modifier == 'S' then
        return after_modifier:upper()
    end
    if modifier then
        special = after_modifier
        modifier = MODIFIER_MAP[modifier:lower()]
        assert(modifier)
    end
    special = special:lower()

    local mapped_special = SPECIALS_MAP[special]
    if mapped_special then
        special = mapped_special
    elseif special:match[=[^[Ff]%d+$]=] then
        special = special:lower()
    end

    if modifier then
        return modifier .. '-' .. special
    else
        return special
    end
end

---@param options MoonicipalSelectSource The options for the user to select from
---@param opts MoonicipalSelectOptions
return function(options, opts)
    local new_opts = {
        fzf_opts = {
            ['--with-nth'] = '2..',
            ['--delimiter'] = '\t',
        },
        keymap = {
            fzf = {},
        }
    }
    if opts.prompt then
        new_opts.prompt = opts.prompt .. '> '
    end

    local format_item = util.transformer_as_function(opts.format)
    local register, fetch = tagged_items_register_and_fetch(format_item)

    local new_options
    local preselect_index = opts.preselect
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
            if preselect_index ~= nil then
                preselect_index = vim.iter(ipairs(new_options)):find(function(_, key)
                    return preselect_index == key
                end)
            end
            new_opts.fzf_opts['--with-nth'] = nil
            fetch = function(key)
                return options[key]
            end
        end
    end

    if opts.preview then
        new_opts.preview = function(item)
            return util.default_transformer(opts.preview(fetch(item[1])))
        end
    end

    if preselect_index then
        new_opts.keymap.fzf['load'] = ('pos(%d)'):format(preselect_index)
    end

    return util.resume_with(function(resumer)
        new_opts.actions = {}

        local function add_action(fzf_keycode, return_marker, action_opts)
            action_opts = vim.tbl_extend('keep', action_opts, {multi = opts.multi})
            if action_opts.multi then
                new_opts.fzf_opts['--multi'] = true
            end
            new_opts.actions[fzf_keycode] = function(result, ctx)
                if action_opts.query then
                    resumer(ctx.last_query, return_marker)
                elseif action_opts.multi then
                    resumer(vim.tbl_map(fetch, result), return_marker)
                else
                    resumer(fetch(result[1]), return_marker)
                end
            end
        end

        add_action('default', nil, {})

        for k, v in pairs(opts.actions or {}) do
            if type(k) == 'number' then
                add_action(keycode_to_fzf(v), v, {})
            else
                add_action(keycode_to_fzf(k), k, v)
            end
        end

        require'fzf-lua'.fzf_exec(new_options, new_opts)
    end)
end
