require("utils")

local plugins = {}

plugins["tokyonight"] = {
	"folke/tokyonight.nvim",
	opts = {
		style = "moon",
		transparent = true,
	},
}

for _, v in pairs(plugins) do
	v.lazy = true
end

return plugins
