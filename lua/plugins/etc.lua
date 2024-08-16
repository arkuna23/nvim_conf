---@type table<string, PlugSpec>
local plugins = {}

plugins["wakatime"] = {
	"wakatime/vim-wakatime",
	categories = "etc",
	event = "User Load",
	cmd = "WakaTimeApiKey",
}

-- copilot
plugins["copilot-cmp"] = {
	"zbirenbaum/copilot-cmp",
	categories = { "ai", "copilot" },
	dependencies = {
		"copilot.lua",
		"hrsh7th/nvim-cmp",
	},
	event = { "InsertEnter", "CmdlineEnter" },
}

plugins["copilot"] = {
	"zbirenbaum/copilot.lua",
	categories = { "ai", "copilot" },
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

-- codeium
plugins["codeium"] = {
	"Exafunction/codeium.nvim",
	categories = { "ai", "codeium" },
	build = ":Codeium Auth",
	cmd = "Codeium",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"hrsh7th/nvim-cmp",
	},
	opts = function(_, _)
		return {
			enable_chat = true,
		}
	end,
}

-- lib
plugins["plenary"] = {
	"nvim-lua/plenary.nvim",
	enabled = true,
	lazy = true,
}

return plugins
