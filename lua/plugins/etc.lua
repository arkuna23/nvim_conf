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
	config = function(_, opts)
		local copilot_cmp = require("copilot_cmp")
		copilot_cmp.setup(opts)
	end,
}

plugins["copilot-lualine"] = {
	"AndreM222/copilot-lualine",
	categories = { "ai", "copilot" },
	dependencies = {
		"copilot.lua",
		"nvim-lualine/lualine.nvim",
	},
	event = { "InsertEnter", "CmdlineEnter" },
}

plugins["copilot"] = {
	"arkuna23/copilot.lua",
	categories = { "ai", "copilot" },
	cmd = "Copilot",
	branch = "pr",
	build = ":Copilot auth",
	opts = function()
		local local_v = require("local_v")
		return {
			suggestion = { enabled = false },
			panel = { enabled = false },
			auth_provider_url = local_v.copilot_auth_url,
			filetypes = {
				markdown = true,
				help = true,
				lua = true,
				python = true,
				rust = true,
			},
		}
	end,
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
