local manager = require("lib.manager")
local config = require("config.init")

COLORSCHEME = "tokyonight"

vim.api.nvim_create_user_command(
	"TogglePluginsEnabled",
	manager.toggle_plugin_enabled,
	{ desc = "toggle lazy.nvim and plugins state" }
)

--disable shada load at startup
vim.opt.shadafile = "NONE"
vim.api.nvim_create_autocmd("CmdlineEnter", {
	once = true,
	callback = function()
		local shada = vim.fn.stdpath("state") .. "/shada/main.shada"
		vim.o.shadafile = shada
		vim.api.nvim_command("rshada! " .. shada)
	end,
})

if manager.plugin_enabled() then
	manager.load_lazy()
else
	config.setup()
end
