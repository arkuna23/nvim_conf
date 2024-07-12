require("lib.util")
local manager = require("lib.manager")
local config = require("config.init")

COLORSCHEME = "tokyonight"

vim.api.nvim_create_user_command(
	"TogglePluginsEnabled",
	manager.toggle_plugin_enabled,
	{ desc = "toggle lazy.nvim and plugins state" }
)

if manager.plugin_enabled() then
	manager.load_lazy()
else
	config.setup()
end
