local g = vim.g
local opt = vim.opt

g.encoding = "UTF-8"
g.have_nerd_font = true
opt.fileencoding = "utf-8"
vim.opt.termguicolors = true

opt.number = true
opt.relativenumber = true
opt.clipboard:append("unnamedplus")
opt.signcolumn = "yes"
opt.colorcolumn = "100"

opt.tabstop = 4
opt.softtabstop = 4
opt.shiftround = true
opt.expandtab = true
vim.o.shiftwidth = 4
opt.mouse = "a"
opt.timeoutlen = 500

local win_height = vim.fn.winheight(0)
opt.scrolloff = math.floor((win_height - 1) / 2)
opt.sidescrolloff = math.floor((win_height - 1) / 2)

return {}
