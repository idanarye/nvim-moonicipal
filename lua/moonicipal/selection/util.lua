local M = {}

function M.tagged_items_register_and_fetch(formatter)
    local len = 0
    local items = {}

    local function register(item)
        local formatted = formatter(item)
        len = len + 1
        items[len] = item
        return ('%d\t%s'):format(len, formatted)
    end

    local function fetch(formatted)
        local tag = vim.gsplit(formatted, '\t', {plain = true})()
        local index = tonumber(tag)
        return items[index]
    end

    return register, fetch
end

return M
