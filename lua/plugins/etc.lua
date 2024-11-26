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
	"zbirenbaum/copilot.lua",
	categories = { "ai", "copilot" },
	cmd = "Copilot",
	build = ":Copilot auth",
	opts = function()
		local succ, local_v = pcall(require, "local_v")
		return {
			suggestion = { enabled = false },
			panel = { enabled = false },
			auth_provider_url = succ and local_v.copilot_auth_url or nil,
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

plugins["avante"] = {
	"yetone/avante.nvim",
	categories = "ai",
	event = "User Load",
	version = false, -- set this if you want to always pull the latest change
	opts = {
		provider = "copilot",
		auto_suggestions_provider = "copilot",
		behaviour = {
			auto_suggestions = true,
		},
	},
	-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
	build = "make",
	-- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"stevearc/dressing.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		--- The below dependencies are optional,
		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
		"zbirenbaum/copilot.lua", -- for providers='copilot'
		{
			-- support for image pasting
			"HakonHarnes/img-clip.nvim",
		},
		{
			-- Make sure to set this up properly if you have lazy=true
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				file_types = { "markdown", "Avante" },
			},
			ft = { "markdown", "Avante" },
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
