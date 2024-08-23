---@type table<string, PlugSpec>
local plugins = {}

plugins["tokyonight"] = {
	"folke/tokyonight.nvim",
	categories = "colorschemes",
	opts = {
		style = "moon",
		transparent = true,
	},
}

for _, v in pairs(plugins) do
	v.lazy = true
end

return plugins
