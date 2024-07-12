local plugins = {}

-- session manager
plugins["persistence"] = {
	"folke/persistence.nvim",
	event = "User Load",
	cmd = "RestoreSession",
	opts = { options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" } },
	init = function()
		vim.api.nvim_create_user_command("RestoreSession", function()
			require("persistence").load()
		end, {})
	end,
	keys = {
		{
			"<leader>qs",
			function()
				require("persistence").load()
			end,
			desc = "Restore Session",
		},
		{
			"<leader>ql",
			function()
				require("persistence").load({ last = true })
			end,
			desc = "Restore Last Session",
		},
		{
			"<leader>qd",
			function()
				require("persistence").stop()
			end,
			desc = "Don't Save Current Session",
		},
	},
}

plugins["wakatime"] = {
	"wakatime/vim-wakatime",
	event = "User Load",
	cmd = "WakaTimeApiKey",
}

plugins["copilot"] = {
	"zbirenbaum/copilot.lua",
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

plugins["plenary"] = {
	"nvim-lua/plenary.nvim",
	lazy = true,
}

return plugins
