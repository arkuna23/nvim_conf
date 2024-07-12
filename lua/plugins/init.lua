local utils = require("lib.util")

local function trigger_user_load()
	vim.api.nvim_exec_autocmds("User", { pattern = "Load" })
	utils.nvim_loaded = true
end

-- User Load: triggered when editing a file
vim.api.nvim_create_autocmd("User", {
	pattern = "VeryLazy",
	callback = function()
		if vim.bo.filetype == "dashboard" then
			vim.api.nvim_create_autocmd("BufRead", {
				once = true,
				callback = trigger_user_load,
			})
		else
			trigger_user_load()
		end
	end,
})

local plugins = vim.tbl_extend(
	"keep",
	require("plugins.ui"),
	require("plugins.lsp.core"),
	require("plugins.lsp.lang"),
	require("plugins.colorschemes"),
	require("plugins.editor"),
	require("plugins.dap"),
	require("plugins.etc")
)
return utils.table2array(plugins)
