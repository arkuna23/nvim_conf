local manager = lazy_require("lib.manager")
local util = lazy_require("lib.util")

COLORSCHEME = "tokyonight"

vim.api.nvim_create_user_command(
	"TogglePluginsEnabled",
	manager.toggle_plugins_enabled,
	{ desc = "toggle lazy.nvim and plugins state" }
)

if not util.is_docker() then
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
end

require("config.init")

-- prevent file deletion while saving
local file = vim.fs.find(
	{ "package.json", "webpack.config.js", ".eslintrc.js" },
	{ upward = true, type = "file" }
)[1]
if file and vim.fn.filereadable(file) == 1 then
	vim.o.backupcopy = "yes"
end

--disable plugins if file size bigger than 4mb
local loadplugin = true
local filepath = vim.api.nvim_buf_get_name(0)
if vim.fn.filereadable(filepath) == 1 then
	local filesize = vim.fn.getfsize(filepath) / (1024 * 1024)
	if filesize > 2 then
		loadplugin = false
	end
end

if manager.plugins_enabled() and loadplugin then
	manager.load_lazy()
else
	if vim.g.neovide then
		require("config.vide")
	end
end
