local M = {}

local function async_wrap(fn, argc)
	return require("plenary.async").wrap(fn, argc)
end

--- @param cmd (string[]) Command to execute
--- @param opts vim.SystemOpts? Options
--- @return vim.SystemCompleted
M.system = function(cmd, opts)
	local fn = async_wrap(vim.system, 3)
	M.system = fn
	return fn(cmd, opts)
end

return M
