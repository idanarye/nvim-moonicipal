local M = {}

local util = require'moonicipal.util'

---@class MoonicipalInputBufferOptions
---Run to configure the buffer
---@field buf_init? function | string
---Default text to put in the buffer
---@field default? string | string[]
---BuffLS integration - attach this BuffLS to the input buffer
---@field buffls? table

---@param opts MoonicipalInputBufferOptions
---@return string
function M.input_buffer(opts)
    vim.cmd'botright new'
    util.fake_scratch_buffer()
    local bufnr = vim.api.nvim_get_current_buf()
    if opts.default then
        util.set_buf_contents(bufnr, opts.default)
    end

    if opts.buffls then
        vim.cmd.setfiletype(opts.buffls.language)
        opts.buffls:for_buffer(bufnr)
        if opts.default then
            opts.buffls:add_action('Restore default', function()
                util.set_buf_contents(bufnr, opts.default)
            end)
        end
    end

    util.run_fn_or_cmd(opts.buf_init)

    local result = util.resume_with(function(resume)
        vim.api.nvim_create_autocmd('BufDelete', {
            buffer = 0,
            callback = function()
                local lines = util.get_buf_contents(bufnr)
                vim.schedule(function()
                    resume(lines)
                end)
            end,
        })
    end)
    return result
end

return M
