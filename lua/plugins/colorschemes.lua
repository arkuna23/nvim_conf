local plugins = {}

plugins["tokyonight"] = {
	"folke/tokyonight.nvim",
	lazy = true,
	event = "VeryLazy",
	opts = {
		style = "moon",
		transparent = true,
	},
	config = function(_, opts)
		require("tokyonight").setup(opts)
	end,
}

return plugins
