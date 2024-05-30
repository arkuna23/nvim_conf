local M = {}

M.setup = function()
	vim.api.nvim_command("highlight LineNr guifg=#bbbbbb ctermfg=gray")
end

return M
