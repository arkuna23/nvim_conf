local M = {}

---convert table elements to array
---@param table table
---@return table
M.table2array = function(table)
    local array = {}
    for _, v in pairs(table) do
        array[#array + 1] = v
    end
    return array
end

---read file content into lines
---@param path string
---@return table | nil
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

---split string by delimiter
---@param inputString string
---@param delimiter string
---@return table
string.split = function(inputString, delimiter)
    local result = {}
    local pattern = "(.-)" .. delimiter .. "()"
    local currentPosition = 1
    for part, _ in string.gmatch(inputString, pattern) do
        result[currentPosition] = part
        currentPosition = currentPosition + 1
    end
    return result
end

---pad string to specified length
---@param inputString string
---@param length number
---@param padding string
---@return string | nil
string.padString = function(inputString, length, padding)
    if #padding ~= 1 then
        return nil
    end

    local strLength = #inputString
    if strLength >= length then
        return inputString
    else
        local spaces = length - strLength
        return inputString .. string.rep(padding, spaces)
    end
end

M.loaded = false

return M
