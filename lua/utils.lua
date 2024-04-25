local M = {}

M.mergeTables = function(...)
    local tables = { ... }
    local result = {}
    for _, t in ipairs(tables) do
        for k, v in pairs(t) do
            result[k] = v
        end
    end
    return result
end

M.table2array = function(table)
    local array = {}
    for _, v in pairs(table) do
        array[#array + 1] = v
    end
    return array
end

M.readFileLines = function(path)
    local file = io.open(path, "r")
    if not file then
        return nil
    end
    local lines = {}
    for line in file:lines() do
        lines[#lines + 1] = line
    end
    file:close()
    return lines
end

M.configRoot = vim.fn.stdpath('config')

return M