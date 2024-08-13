---@type table<string, PlugSpec>
local plugins = {}

plugins["wakatime"] = {
	"wakatime/vim-wakatime",
	categories = "etc",
	event = "User Load",
	cmd = "WakaTimeApiKey",
}

plugins["copilot-cmp"] = {
	"zbirenbaum/copilot-cmp",
	categories = "ai",
	dependencies = "copilot.lua",
	event = { "InsertEnter", "CmdlineEnter" },
}

plugins["copilot"] = {
	"zbirenbaum/copilot.lua",
	categories = "ai",
	cmd = "Copilot",
	build = ":Copilot auth",
	opts = {
		suggestion = { enabled = false },
		panel = { enabled = false },
		filetypes = {
			markdown = true,
			help = true,
			lua = true,
			python = true,
			rust = true,
		},
	},
}

-- lib
plugins["plenary"] = {
	"nvim-lua/plenary.nvim",
	enabled = true,
	lazy = true,
}

return plugins
