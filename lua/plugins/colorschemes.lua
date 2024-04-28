local plugins = {}

plugins["tokyonight"] = {
	"folke/tokyonight.nvim",
	lazy = true,
	opts = {
		style = "moon",
		transparent = true,
	},
}

return plugins
