local M = {}

local async_wrap
--- protcted plenary.async.wrap
--- @param fn function
--- @param argc integer
--- @return function
async_wrap = function(fn, argc)
	local succ, res = pcall(require, "plenary.async")
	assert(succ, "Please enable plenary.nvim plugin")

	local fn_self = function(fn_new, argc_new)
		return res.wrap(fn_new, argc_new)
	end
	async_wrap = fn_self
	return fn_self(fn, argc)
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
