---@type table<string, PlugSpec>
local plugins = {}

local manager = lazy_require("lib.manager")

plugins["nvim-cmp"] = {
	"hrsh7th/nvim-cmp",
	categories = "editor",
	dependencies = {
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		"rafamadriz/friendly-snippets",
		"onsails/lspkind-nvim",
	},
	keys = {
		{
			"<Tab>",
			function()
				return vim.snippet.active({ direction = 1 }) and "<cmd>lua vim.snippet.jump(1)<cr>"
					or "<Tab>"
			end,
			expr = true,
			silent = true,
			mode = { "i", "s" },
		},
		{
			"<S-Tab>",
			function()
				return vim.snippet.active({ direction = -1 })
						and "<cmd>lua vim.snippet.jump(-1)<cr>"
					or "<Tab>"
			end,
			expr = true,
			silent = true,
			mode = { "i", "s" },
		},
	},
	event = { "InsertEnter", "CmdlineEnter" },
	config = function()
		local lspkind = require("lspkind")
		lspkind.init({
			preset = "codicons",
			symbol_map = require("lib.symbols"),
		})

		local cmp = require("cmp")
		local sources2 = {
			{ name = "copilot" },
			{ name = "buffer" },
			{ name = "path" },
		}
		if manager.get_plug_spec("copilot-cmp").enabled then
			sources2[#sources2 + 1] = { name = "copilot" }
		end
		---@diagnostic disable-next-line: redundant-parameter
		cmp.setup({
			snippet = {
				expand = function(args)
					require("luasnip").lsp_expand(args.body)
				end,
			},
			sorting = {
				comparators = {
					require("clangd_extensions.cmp_scores"),
				},
				priority_weight = 1,
			},

			sources = cmp.config.sources({
				{ name = "lazydev" },
			}, {
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
				{ name = "crates" },
				{ name = "codeium" },
			}, sources2),
			mapping = cmp.mapping.preset.insert({
				["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
				["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
				["<C-b>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
				["<C-Space>"] = cmp.mapping.complete(),
				["<C-e>"] = cmp.mapping.abort(),
				["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
				["<S-CR>"] = cmp.mapping.confirm({
					behavior = cmp.ConfirmBehavior.Replace,
					select = true,
				}), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
				["<C-CR>"] = function(fallback)
					cmp.abort()
					fallback()
				end,
			}),
			formatting = {
				fields = { "abbr", "menu", "kind" },
				format = lspkind.cmp_format({
					mode = "symbol",
					maxwidth = 30,
				}),
			},
		})

		---@diagnostic disable-next-line: undefined-field
		cmp.setup.cmdline({ "/", "?" }, {
			mapping = cmp.mapping.preset.cmdline(),
			sources = {
				{ name = "buffer" },
			},
		})

		---@diagnostic disable-next-line: undefined-field
		cmp.setup.cmdline(":", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = cmp.config.sources({
				{ name = "path" },
			}, {
				{ name = "cmdline" },
			}),
		})

		local cmp_autopairs = require("nvim-autopairs.completion.cmp")
		cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done({ map_char = { tex = "" } }))
	end,
}

plugins["sniprun"] = {
	"michaelb/sniprun",
	categories = "editor",
	cmd = "SnipRun",
	branch = "master",
	build = "sh install.sh",
	keys = {
		{
			"<leader>sr",
			"<Cmd>SnipRun<CR>",
			mode = "v",
			desc = "SnipRun: run code",
		},
	},
	opts = {
		display = { "Terminal" },
		display_options = {
			terminal_position = "vertical",
			terminal_width = 45,
		},
	},
}

-- formatting
plugins["conform"] = {
	"stevearc/conform.nvim",
	categories = "editor",
	event = { "User Load" },
	cmd = { "ConformInfo" },
	keys = {
		{
			-- Customize or remove this keymap to your liking
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "n",
			desc = "Format buffer",
		},
	},
	-- Everything in opts will be passed to setup()
	opts = function()
		local config = require("plugins.conf")
		return {
			-- Define your formatters
			formatters_by_ft = config.formatter().ft,
			-- Customize formatters
			formatters = config.formatter().config,
		}
	end,
	init = function()
		-- If you want the formatexpr, here is the place to set it
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
	config = function(_, opts)
		require("conform").setup(opts)
		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = "*",
			callback = function(args)
				local filetype = vim.bo[args.buf].filetype
				if
					not table.list_contains(
						require("plugins.conf").formatter().format_on_save_exclude_ft,
						filetype
					)
				then
					require("conform").format({ bufnr = args.buf })
				end
			end,
		})
	end,
}

plugins["nvim-treesitter"] = {
	"nvim-treesitter/nvim-treesitter",
	categories = "editor",
	build = ":TSUpdate",
	dependencies = { "hiphish/rainbow-delimiters.nvim" },
	event = "User Load",
	main = "nvim-treesitter",
	opts = function()
		return {
			ensure_installed = require("plugins.conf").treesitter,
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
				disable = {
					"latex",
				},
			},
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<CR>",
					node_incremental = "<CR>",
					node_decremental = "<BS>",
					scope_incremental = "<TAB>",
				},
			},
			indent = {
				enable = true,
				-- conflicts with flutter-tools.nvim, causing performance issues
				disable = { "dart" },
			},
		}
	end,
	config = function(_, opts)
		require("nvim-treesitter.install").prefer_git = true
		require("nvim-treesitter.configs").setup(opts)

		vim.opt.foldmethod = "expr"
		vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
		vim.opt.foldenable = false

		local rainbow_delimiters = require("rainbow-delimiters")

		vim.g.rainbow_delimiters = {
			strategy = {
				[""] = rainbow_delimiters.strategy["global"],
				vim = rainbow_delimiters.strategy["local"],
			},
			query = {
				[""] = "rainbow-delimiters",
				lua = "rainbow-blocks",
			},
			highlight = {
				"RainbowDelimiterRed",
				"RainbowDelimiterYellow",
				"RainbowDelimiterBlue",
				"RainbowDelimiterOrange",
				"RainbowDelimiterGreen",
				"RainbowDelimiterViolet",
				"RainbowDelimiterCyan",
			},
		}
	end,
}

plugins["neoconf"] = {
	"folke/neoconf.nvim",
	categories = "editor",
	cmd = "Neoconf",
	opts = {},
}

plugins["nvim-autopairs"] = {
	"windwp/nvim-autopairs",
	categories = "editor",
	event = "InsertEnter",
	main = "nvim-autopairs",
	opts = {},
}

plugins["mini-surround"] = {
	"echasnovski/mini.surround",
	categories = "editor",
	recommended = true,
	keys = {
		{ "gsa", desc = "Add Surrounding", mode = { "n", "v" } },
		{ "gsd", desc = "Delete Surrounding" },
		{ "gsf", desc = "Find Right Surrounding" },
		{ "gsF", desc = "Find Left Surrounding" },
		{ "gsh", desc = "Highlight Surrounding" },
		{ "gsr", desc = "Replace Surrounding" },
		{ "gsn", desc = "Update `MiniSurround.config.n_lines`" },
	},
	opts = {
		mappings = {
			add = "gsa", -- Add surrounding in Normal and Visual modes
			delete = "gsd", -- Delete surrounding
			find = "gsf", -- Find surrounding (to the right)
			find_left = "gsF", -- Find surrounding (to the left)
			highlight = "gsh", -- Highlight surrounding
			replace = "gsr", -- Replace surrounding
			update_n_lines = "gsn", -- Update `n_lines`
		},
	},
}
plugins["mini.bufremove"] = {
	"echasnovski/mini.bufremove",
	categories = "editor",
	keys = {
		{
			"<leader>bd",
			function()
				local bd = require("mini.bufremove").delete
				if vim.bo.modified then
					local choice = vim.fn.confirm(
						("Save changes to %q?"):format(vim.fn.bufname()),
						"&Yes\n&No\n&Cancel"
					)
					if choice == 1 then -- Yes
						vim.cmd.write()
						bd(0)
					elseif choice == 2 then -- No
						bd(0, true)
					end
				else
					bd(0)
				end
			end,
			desc = "Delete Buffer",
		},
		{
			"<leader>bD",
			function()
				require("mini.bufremove").delete(0, true)
			end,
			desc = "Delete Buffer (Force)",
		},
	},
}
plugins["img-clip"] = {
	"HakonHarnes/img-clip.nvim",
	categories = "editor",
	opts = {
		default = {
			dir_path = "images",
			embed_image_as_base64 = false,
			prompt_for_file_name = false,
			relative_to_current_file = true,
			drag_and_drop = {
				insert_mode = true,
			},
		},
	},
	keys = {
		-- suggested keymap
		{ "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
	},
}

-- session manager
plugins["persistence"] = {
	"folke/persistence.nvim",
	categories = "editor",
	event = "User Load",
	cmd = "RestoreSession",
	opts = {
		options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp" },
	},
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
