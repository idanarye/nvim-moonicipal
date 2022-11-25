local M = {}

local util = require'moonicipal/util'
local tasks_file = require'moonicipal/tasks_file'

M.settings = require'moonicipal/settings'

local function get_file_name()
    return M.settings.file_prefix .. '.moonicipal.lua'
end

---@param config MoonicipalSettings
function M.setup(config)
    for key, value in pairs(config) do
        M.settings[key] = value
    end

    local function cmd_complete(arg_lead)
        return vim.tbl_filter(function(task_name)
            return vim.startswith(task_name, arg_lead)
        end, vim.tbl_keys(M.read_task_file().tasks))
    end

    vim.api.nvim_create_user_command('MC', function(ctx)
        if ctx.fargs[1] == nil then
            M.read_task_file():select_and_invoke()
        else
            M.read_task_file():invoke(unpack(ctx.fargs))
        end
    end, { nargs = '*', complete = cmd_complete })

    -- These are all temporary. Will be replaced with more proper solution
    local function define_edit_function(cmd_name, edit_cmd)
        vim.api.nvim_create_user_command(cmd_name, function(ctx)
            tasks_file.open_for_edit(edit_cmd, get_file_name(), unpack(ctx.fargs))
        end, { nargs = '?', complete = cmd_complete })
    end
    define_edit_function('MCedit', 'edit')
    define_edit_function('MCsedit', 'split')
    define_edit_function('MCvedit', 'vsplit')
    define_edit_function('MCtedit', 'tabnew')
end

---@return Populator | fun(opts: Decoration) | MoonicipalTaskClassInside
function M.tasks_file()
    return tasks_file.populator()
end

function M.select_and_invoke()
    M.read_task_file():select_and_invoke()
end

function M.invoke(task_name, ...)
    M.read_task_file():invoke(task_name, ...)
end

function M.read_task_file()
    return tasks_file.load(get_file_name())
end

---@class MoonicipalInputOptions
---@field prompt? string 
---@field default? string

---@param opts MoonicipalInputOptions
function M.input(opts)
    local new_opts = {}
    if opts then
        opts.prompt = new_opts.prompt
        opts.default = new_opts.default
    end
    return util.resume_with(function(resumer)
        vim.ui.input(new_opts, resumer)
    end)
end

---@class MoonicipalSelectOptions
---@field prompt? string 
---@field format? MoonicipalOptionTransformer

---@param opts MoonicipalSelectOptions
function M.select(options, opts)
    local new_opts = {}
    if opts then
        new_opts.prompt = opts.prompt
        if opts.format then
            new_opts.format_item = util.transformer_as_function(opts.format)
        end
    end
    return util.resume_with(function(resumer)
        vim.ui.select(options, new_opts, resumer)
    end)
end

function M.fix_echo()
    util.fix_echo()
end

function M.sleep(timeout)
    util.sleep(timeout)
end

function M.fake_scratch_buffer(set_buffer_name_to)
    util.fake_scratch_buffer(set_buffer_name_to)

end

function M.get_buf_contents(buf_nr)
    return util.get_buf_contents(buf_nr)
end

function M.set_buf_contents(buf_nr, content)
    util.set_buf_contents(buf_nr, content)
end

return M
