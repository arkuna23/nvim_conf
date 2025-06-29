---@type table<string, PlugSpec>
local plugins = {}

plugins["nvim-lspconfig"] = {
	"neovim/nvim-lspconfig",
	event = "VeryLazy",
	categories = "lsp",
	config = function(_, _)
		vim.defer_fn(function()
			require("mason-lspconfig")
			for k, v in pairs(require("plugins.conf").lsp()) do
				if string.sub(k, 1, 1) ~= "_" then
					if not require("neoconf").get(k .. ".disable") then
						local opts = v()
						require("lspconfig")[k].setup(opts)
					end
				end
			end
			vim.api.nvim_command("LspStart")
		end, 0)
	end,
}

plugins["mason-lspconfig"] = {
	"mason-org/mason-lspconfig.nvim",
	lazy = true,
	categories = "lsp",
	dependencies = {
		"williamboman/mason.nvim",
	},
	opts = function()
		return {
			ensure_installed = table.keys(require("plugins.conf").lsp()),
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
			codelens = {
				enabled = false,
			},
		}
	end,
	config = function(_, opts)
		require("mason").setup(opts)

		-- reload lsp
		local mr = require("mason-registry")
		mr:on("package:install:success", function()
			vim.defer_fn(function()
				-- trigger FileType event to possibly load this newly installed LSP server
				require("lazy.core.handler.event").trigger({
					event = "FileType",
					buf = vim.api.nvim_get_current_buf(),
				})
			end, 100)
		end)

		-- install packages
		mr.refresh(function()
			for _, tool in ipairs(require("plugins.conf").mason.packages) do
				local p = mr.get_package(tool)
				if not p:is_installed() then
					p:install()
				end
			end
		end)

		-- ui config
		vim.diagnostic.config({
			virtual_text = true,
			signs = true,
			update_in_insert = true,
		})
		local symbols = require("lib.symbols")
		local signs = {
			Error = symbols.Error,
			Warn = symbols.Warn,
			Hint = symbols.Hint,
			Info = symbols.Info,
		}
		for type, icon in pairs(signs) do
			local hl = "DiagnosticSign" .. type
			vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
		end
	end,
}

plugins["LuaSnip"] = {
	"L3MON4D3/LuaSnip",
	categories = "lsp",
-- stylua: ignore
    keys = {
        {
            "<tab>",
            function()
                return require("luasnip").jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
            end,
            expr = true, silent = true, mode = "i",
        },
        { "<tab>", function() require("luasnip").jump(1) end, mode = "s" },
        { "<s-tab>", function() require("luasnip").jump(-1) end, mode = { "i", "s" } },
    },
}

return plugins
