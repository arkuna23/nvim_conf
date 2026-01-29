local g = vim.g
local opt = vim.opt

g.encoding = "UTF-8"
g.have_nerd_font = true
opt.fileencoding = "utf-8"
opt.termguicolors = true

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.colorcolumn = "100"

opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.shiftround = true

opt.mouse = "a"
opt.timeoutlen = 500

opt.clipboard:append("unnamedplus")

if g.neovide then
	vim.g.neovide_input_use_subcommand = true
elseif vim.fn.has("nvim-0.10") == 1 then
	vim.g.clipboard = {
		name = "OSC 52",
		copy = {
			["+"] = require("vim.ui.clipboard.osc52").copy("+"),
			["*"] = require("vim.ui.clipboard.osc52").copy("*"),
		},
	}
end

opt.scrolloff = 10
opt.sidescrolloff = 10

return {}
