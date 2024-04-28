local plugins = {}

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

return plugins
