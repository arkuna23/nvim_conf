local M = {}

vim.g.mapleader = " "
vim.api.nvim_set_keymap("t", "<Esc><Esc>", "<C-\\><C-n>", { noremap = true })

-- change window size
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

vim.api.nvim_set_keymap("n", "J", "<C-d>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "K", "<C-u>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "J", "<C-d>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "K", "<C-u>", { noremap = true, silent = true })

return M
