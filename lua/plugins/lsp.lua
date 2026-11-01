---@type table<string, PlugSpec>
local plugins = {}

plugins["nvim-lspconfig"] = {
	"neovim/nvim-lspconfig",
	event = "User Load",
	categories = "lsp",
	config = function(_, _)
		require("mason-lspconfig")
		require("neoconf")
		local project = require("lib.project_lsp")
		local servers = {}
		for name, spec in pairs(require("plugins.conf").lsp()) do
			vim.lsp.config(name, spec())
			vim.lsp.config(name, project.wrap(name, vim.lsp.config[name]))
			servers[#servers + 1] = name
		end
		vim.lsp.enable(servers)
	end,
}

plugins["mason-lspconfig"] = {
	"mason-org/mason-lspconfig.nvim",
	lazy = true,
	categories = "lsp",
	dependencies = {
		"mason-org/mason.nvim",
	},
	opts = function()
		return {
			ensure_installed = table.keys(require("plugins.conf").lsp()),
			automatic_enable = false,
		}
	end,
}

plugins["refactoring"] = {
	"ThePrimeagen/refactoring.nvim",
	event = "User Load",
	categories = "lsp",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
}

plugins["mason"] = {
	"mason-org/mason.nvim",
	event = "User Load",
	categories = "lsp",
	cmd = "Mason",
	build = ":MasonUpdate",
	opts = function()
		local symbols = require("lib.symbols")
		return {
			ui = {
				icons = {
					package_installed = symbols.Affirmative,
					package_pending = symbols.Pending,
					package_uninstalled = symbols.Negative,
				},
			},
		}
	end,
	config = function(_, opts)
		require("mason").setup(opts)

		local mr = require("mason-registry")
		mr:on(
			"package:install:success",
			vim.schedule_wrap(function()
				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
						vim.api.nvim_exec_autocmds("FileType", { buffer = buf, modeline = false })
					end
				end
			end)
		)
		mr.refresh(vim.schedule_wrap(function(success)
			if not success then
				vim.notify("Mason registry refresh failed; see :MasonLog", vim.log.levels.ERROR)
				return
			end
			for _, tool in ipairs(require("plugins.conf").mason.packages()) do
				local ok, pkg = pcall(mr.get_package, tool)
				if not ok then
					vim.notify(tostring(pkg), vim.log.levels.ERROR)
				elseif not pkg:is_installed() and not pkg:is_installing() then
					pkg:install({}, function(installed, err)
						if not installed then
							vim.schedule(function()
								vim.notify(
									"Mason " .. tool .. ": " .. tostring(err),
									vim.log.levels.ERROR
								)
							end)
						end
					end)
				end
			end
		end))
		local symbols = require("lib.symbols")
		local severity = vim.diagnostic.severity
		vim.diagnostic.config({
			virtual_text = true,
			update_in_insert = true,
			signs = {
				text = {
					[severity.ERROR] = symbols.Error,
					[severity.WARN] = symbols.Warn,
					[severity.HINT] = symbols.Hint,
					[severity.INFO] = symbols.Info,
				},
			},
		})
	end,
}

return plugins
