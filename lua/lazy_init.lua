local manager = lazy_require("lib.manager")

COLORSCHEME = "tokyonight"

vim.api.nvim_create_user_command(
	"TogglePluginsEnabled",
	manager.toggle_plugin_enabled,
	{ desc = "toggle lazy.nvim and plugins state" }
)

--disable shada load at startup
vim.o.shadafile = "NONE"
vim.api.nvim_create_autocmd("CmdlineEnter", {
	once = true,
	callback = function()
		local shada = vim.fn.stdpath("state") .. "/shada/main.shada"
		vim.o.shadafile = shada
		vim.api.nvim_command("rshada! " .. shada)
	end,
})

require("config.init")
if manager.plugin_enabled() then
	manager.load_lazy()
else
	if vim.g.neovide then
		require("config.vide")
	end
end
