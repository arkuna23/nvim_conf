local M = {}

M.setup = function()
	vim.cmd("colorscheme tokyonight")
	vim.api.nvim_command("highlight LineNr guifg=#bbbbbb ctermfg=gray")
end

return M
