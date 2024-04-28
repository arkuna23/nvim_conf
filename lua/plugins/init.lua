local utils = require("utils")

function TriggerUserLoad()
	vim.api.nvim_exec_autocmds("User", { pattern = "Load" })
	utils.loaded = true
end

-- User Load: triggered when editing a file
vim.api.nvim_create_autocmd("User", {
	pattern = "VeryLazy",
	callback = function()
		if vim.bo.filetype == "dashboard" then
			vim.api.nvim_create_autocmd("BufRead", {
				once = true,
				callback = TriggerUserLoad,
			})
		else
			TriggerUserLoad()
		end
	end,
})

local plugins = vim.tbl_extend(
	"keep",
	require("plugins.ui"),
	require("plugins.lsp"),
	require("plugins.colorschemes"),
	require("plugins.etc")
)
return utils.table2array(plugins)
