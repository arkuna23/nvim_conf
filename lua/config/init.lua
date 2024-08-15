require("config.general")
require("config.keymap")

local color = require("config.color")

local M = {}

M.setup = function()
	color.setup()
	if not require('lib.manager').plugin_enabled() and vim.g.neovide then
		require('config.vide').setup()
	end
end
return M
