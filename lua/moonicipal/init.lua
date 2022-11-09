local M = setmetatable({}, {__index = require'moonicipal/util'})

local tasks_file = require'moonicipal/tasks_file'

M.settings = require'moonicipal/settings'

local function get_file_name()
    return M.settings.file_prefix .. '.moonicipal.lua'
end

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

---@return Populator | fun(opts: Decoration) | TaskClass
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

function M.input(opts)
    return M.resume_with(function(resumer)
        vim.ui.input(opts, resumer)
    end)
end

function M.select(options, opts)
    return M.resume_with(function(resumer)
        vim.ui.select(options, opts or {}, resumer)
    end)
end

return M
