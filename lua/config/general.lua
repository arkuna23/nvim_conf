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
elseif vim.env.SSH_CONNECTION or vim.env.SSH_TTY then
	opt.clipboard:remove({ "unnamed", "unnamedplus" })
	local clipboard = { name = "OSC 52", copy = {}, paste = {}, cache_enabled = 0 }
	for _, reg in ipairs({ "+", "*" }) do
		local cached = { { "" }, "v" }
		local copy = require("vim.ui.clipboard.osc52").copy(reg)
		clipboard.copy[reg] = function(lines, regtype)
			cached = { vim.deepcopy(lines), regtype }
			copy(lines, regtype)
		end
		clipboard.paste[reg] = function()
			return vim.deepcopy(cached)
		end
	end
	vim.g.clipboard = clipboard
else
	vim.g.clipboard = nil
end

opt.scrolloff = 10
opt.sidescrolloff = 10

vim.filetype.add({
	extension = {
		["code-snippets"] = "jsonc",
	},
})

return {}
