local g = vim.g
local opt = vim.opt

g.encoding = "UTF-8"
opt.fileencoding = "utf-8"

opt.number = true
opt.relativenumber = true
opt.clipboard:append("unnamedplus")
opt.signcolumn = "yes"

opt.tabstop = 4
opt.softtabstop = 4
opt.shiftround = true
opt.expandtab = true
vim.o.shiftwidth = 4
opt.mouse = "a"
opt.timeoutlen = 500

return {}
