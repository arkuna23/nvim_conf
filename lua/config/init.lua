require("config.general")
require("config.keymap")

local color = require("config.color")
local vide = require("config.vide")

local M = {}

M.setup = function()
	color.setup()
	if vim.g.neovide then
		vide.setup()
	end
end
return M
