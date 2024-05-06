local symbols = require("symbols")
require("utils")

local lsp = {}

lsp.flags = {
	debounce_text_changes = 150,
}

lsp.defaultKeybindings = {
	["lsp_info"] = { "<leader>cl", "<cmd>LspInfo<CR>", "n", "Lsp Info" }, -- Lsp Info
	["definitions"] = { "gd", "<cmd>Telescope lsp_definitions<CR>", "n", "Goto Definitions" }, -- Goto Definition
	["references"] = { "gr", "<cmd>Telescope lsp_references<CR>", "n", "References" }, -- References
	["declaration"] = { "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", "n", "Goto Declaration" }, -- Goto Declaration
	["type_implementations"] = { "gI", "<cmd>Telescope lsp_implementations<CR>", "n", "Goto Implementations" }, -- Goto Implementation
	["type_definitions"] = { "gy", "<cmd>Telescope lsp_type_definitions<CR>", "n", "Goto Type Definitions" }, -- Goto Type Definition
	["hover"] = { "K", "<cmd>lua vim.lsp.buf.hover()<CR>", "n", "Hover" }, -- Hover
	["signature_help"] = { "gK", "<cmd>lua vim.lsp.buf.signature_help()<CR>", "n", "Signature Help" }, -- Signature Help
	["signature_help_insert"] = {
		"<c-k>",
		"<cmd>lua vim.lsp.buf.signature_help()<CR>",
		"i",
		"Signature Help (Insert mode)",
	}, -- Signature Help (Insert mode)
	["code_action"] = { "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", "n,v", "Code Action" }, -- Code Action
	["run_codelens"] = { "<leader>cc", "<cmd>lua vim.lsp.codelens.run()<CR>", "n,v", "Run Codelens" }, -- Run Codelens
	["refresh_codelens"] = {
		"<leader>cC",
		"<cmd>lua vim.lsp.codelens.refresh()<CR>",
		"n",
		"Refresh & Display Codelens",
	}, -- Refresh & Display Codelens
	["source_action"] = { "<leader>cA", "<cmd>lua vim.lsp.buf.source_action()<CR>", "n", "Source Action" }, -- Source Action
	["rename"] = { "<leader>cr", "<cmd>lua vim.lsp.buf.rename()<CR>", "n", "Rename" }, -- Rename
	["document_diagnostic"] = {
		"<leader>xx",
		"<cmd>TroubleToggle document_diagnostics<CR>",
		"n",
		"Document Diagnostics",
	}, -- Document Diagnostics
	["workspace_diagnostic"] = {
		"<leader>xX",
		"<cmd>TroubleToggle workspace_diagnostics<CR>",
		"n",
		"Workspace Diagnostics",
	}, -- Workspace Diagnostics
}

lsp.mergeKeybindings = function(newKeybindings)
	return vim.tbl_extend("force", lsp.defaultKeybindings, newKeybindings)
end

lsp.keyAttach = function(buffer, keybindings)
	for _, binding in pairs(keybindings) do
		local modes = vim.split(binding[3] or "n", ",") -- 默认模式为普通模式
		local res, err = pcall(
			vim.keymap.set,
			modes,
			binding[1],
			binding[2],
			{ noremap = true, silent = true, buffer = buffer, desc = binding[4] }
		)
		if not res then
			vim.notify(err, vim.log.levels.ERROR)
			return
		end
	end
end

lsp.treesitter = {
	"c",
	"c_sharp",
	"cpp",
	"css",
	"html",
	"javascript",
	"json",
	"json5",
	"jsonc",
	"lua",
	"python",
	"rust",
	"ron",
	"toml",
	"typescript",
	"bash",
	"tsx",
	"vim",
	"ninja",
}

lsp.ensure_installed = {
	"clangd",
	"css-lsp",
	"emmet-ls",
	"html-lsp",
	"json-lsp",
	"lua-language-server",
	"omnisharp",
	"black",
	"typescript-language-server",
	"autopep8",
	"csharpier",
	"fixjson",
	"prettier",
	"shfmt",
	"shellcheck",
	"stylua",
	"pyright",
	"bash-language-server",
	"codelldb",
}

lsp.config = {
	default = function()
		return {
			capabilities = require("cmp_nvim_lsp").default_capabilities(),
			flags = lsp.flags,
			-- default attach actions
			on_attach = function(client, bufnr)
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
				lsp.keyAttach(bufnr, lsp.defaultKeybindings)

				-- copilot
				if client.name == "copilot" then
					require("copilot_cmp")._on_insert_enter({})
				end
			end,
		}
	end,
	{
		"lua_ls",
		conf = function()
			local runtime_path = vim.split(package.path, ";")
			table.insert(runtime_path, "lua/?.lua")
			table.insert(runtime_path, "lua/?/init.lua")
			return vim.tbl_extend("force", lsp.config.default(), {
				settings = {
					Lua = {
						runtime = {
							version = "LuaJIT",
							path = runtime_path,
						},
						diagnostics = {
							globals = { "vim" },
						},
						workspace = {
							library = vim.api.nvim_get_runtime_file("", true),
							checkThirdParty = false,
						},
						telemetry = {
							enable = false,
						},
						codeLens = {
							enable = true,
						},
					},
				},
			})
		end,
	},
	{
		"omnisharp",
		conf = function()
			return vim.tbl_extend("force", lsp.config.default(), {
				cmd = {
					"dotnet",
					vim.fn.stdpath("data") .. "/mason/packages/omnisharp/libexec/Omnisharp.dll",
				},
				on_attach = function(client, bufnr)
					client.server_capabilities.semanticTokensProvider = nil
					lsp.config.default().on_attach(client, bufnr)
				end,
				enable_editorconfig_support = true,
				enable_ms_build_load_projects_on_demand = false,
				enable_roslyn_analyzers = false,
				organize_imports_on_format = false,
				enable_import_completion = false,
				sdk_include_prereleases = true,
				analyze_open_documents_only = false,
			})
		end,
	},
	{
		"tsserver",
		conf = function()
			return {
				single_file_support = true,
				capabilities = require("cmp_nvim_lsp").default_capabilities(),
				flags = lsp.flags,
				on_attach = function(client, bufnr)
					if #vim.lsp.get_active_clients({ name = "denols" }) > 0 then
						client.stop()
					else
						lsp.disableFormat(client)
						require("lazyvim.plugins.lsp.keymaps").on_attach(client, bufnr)
					end
				end,
			}
		end,
	},
	{
		"emmet_ls",
		conf = function()
			return {
				filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less" },
			}
		end,
	},
	{ "clangd" },
	{ "pyright" },
	{
		"jsonls",
		conf = function()
			return {
				-- lazy-load schemastore when needed
				on_new_config = function(new_config)
					new_config.settings.json.schemas = new_config.settings.json.schemas or {}
					vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
				end,
				settings = {
					json = {
						format = {
							enable = true,
						},
						validate = { enable = true },
					},
				},
			}
		end,
	},
	{ "bashls" },
}

local plugins = {}

-- lsp config
plugins["nvim-treesitter"] = {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	dependencies = { "hiphish/rainbow-delimiters.nvim" },
	event = "User Load",
	pin = true,
	main = "nvim-treesitter",
	opts = {
		ensure_installed = lsp.treesitter,
		highlight = {
			enable = true,
			additional_vim_regex_highlighting = false,
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
	},
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

plugins["mason"] = {
	"williamboman/mason.nvim",
	event = "User Load",
	cmd = "Mason",
	keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
	dependencies = {
		"neovim/nvim-lspconfig",
	},
	build = ":MasonUpdate",
	opts = {
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
	},
	config = function(_, opts)
		require("mason").setup(opts)

		-- install lsp
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
		local function ensure_installed()
			for _, tool in ipairs(lsp.ensure_installed) do
				local p = mr.get_package(tool)
				if not p:is_installed() then
					p:install()
				end
			end
		end
		if mr.refresh then
			mr.refresh(ensure_installed)
		else
			ensure_installed()
		end

		-- configure lspconfig
		local lspconfig = require("lspconfig")
		local default = lsp.config.default()
		for key, conf in pairs(lsp.config) do
			if key ~= "default" then
				if lspconfig[conf[1]] then
					if conf.conf then
						lspconfig[conf[1]].setup(conf.conf())
					else
						lspconfig[conf[1]].setup(default)
					end
				end
			end
		end

		-- ui config
		vim.diagnostic.config({
			virtual_text = true,
			signs = true,
			update_in_insert = true,
		})
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

		vim.api.nvim_command("LspStart")
	end,
}

-- completion
plugins["nvim-autopairs"] = {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	main = "nvim-autopairs",
	opts = {},
}

plugins["nvim-cmp"] = {
	"hrsh7th/nvim-cmp",
	dependencies = {
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		"rafamadriz/friendly-snippets",
		"onsails/lspkind-nvim",
		-- copilot
		{
			"zbirenbaum/copilot-cmp",
			dependencies = "copilot.lua",
			opts = {},
		},
	},
	event = { "InsertEnter", "CmdlineEnter" },
	config = function()
		local lspkind = require("lspkind")
		lspkind.init({
			mode = "symbol",
			preset = "codicons",
			symbol_map = {
				Text = symbols.Text,
				Method = symbols.Method,
				Function = symbols.Function,
				Constructor = symbols.Constructor,
				Field = symbols.Field,
				Variable = symbols.Variable,
				Class = symbols.Class,
				Interface = symbols.Interface,
				Module = symbols.Module,
				Property = symbols.Property,
				Unit = symbols.Unit,
				Value = symbols.Value,
				Enum = symbols.Enum,
				Keyword = symbols.Keyword,
				Snippet = symbols.Snippet,
				Color = symbols.Color,
				File = symbols.File,
				Reference = symbols.Reference,
				Folder = symbols.Folder,
				EnumMember = symbols.EnumMember,
				Constant = symbols.Constant,
				Struct = symbols.Struct,
				Event = symbols.Event,
				Operator = symbols.Operator,
				TypeParameter = symbols.TypeParameter,
				Copilot = symbols.Copilot,
			},
		})

		local cmp = require("cmp")
		---@diagnostic disable-next-line: redundant-parameter
		cmp.setup({
			snippet = {
				expand = function(args)
					require("luasnip").lsp_expand(args.body)
				end,
			},
			sources = cmp.config.sources({
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
				{ name = "copilot", priority = 100 },
			}, {
				{ name = "buffer" },
				{ name = "path" },
			}),
			mapping = cmp.mapping.preset.insert({
				["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
				["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
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

-- formatting
plugins["conform"] = {
	"stevearc/conform.nvim",
	event = { "User Load" },
	cmd = { "ConformInfo" },
	keys = {
		{
			-- Customize or remove this keymap to your liking
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = "",
			desc = "Format buffer",
		},
	},
	-- Everything in opts will be passed to setup()
	opts = {
		-- Define your formatters
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "isort", "black" },
			["javascriptreact"] = { "prettier" },
			["typescriptreact"] = { "prettier" },
			["vue"] = { "prettier" },
			["css"] = { "prettier" },
			["scss"] = { "prettier" },
			["less"] = { "prettier" },
			["html"] = { "prettier" },
			["json"] = { "prettier" },
			["jsonc"] = { "prettier" },
			["yaml"] = { "prettier" },
			["markdown"] = { "prettier" },
			["markdown.mdx"] = { "prettier" },
			["graphql"] = { "prettier" },
			["handlebars"] = { "prettier" },
			javascript = { { "prettierd", "prettier" } },
			cs = { "csharpier" },
		},
		-- Set up format-on-save
		format_on_save = { timeout_ms = 500, lsp_fallback = true },
		-- Customize formatters
		formatters = {
			shfmt = {
				prepend_args = { "-i", "2" },
			},
		},
	},
	init = function()
		-- If you want the formatexpr, here is the place to set it
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}

-- rust
plugins["rustaceanvim"] = {
	"mrcjkb/rustaceanvim",
	version = "^4", -- Recommended
	ft = { "rust" },
	build = "rustup component add rust-analyzer",
	opts = {
		server = {
			on_attach = function(_, bufnr)
				lsp.keyAttach(bufnr, lsp.defaultKeybindings)
			end,
			default_settings = {
				-- rust-analyzer language server configuration
				["rust-analyzer"] = {
					cargo = {
						allFeatures = true,
						loadOutDirsFromCheck = true,
						runBuildScripts = true,
					},
					-- Add clippy lints for Rust.
					checkOnSave = {
						allFeatures = true,
						command = "clippy",
						extraArgs = { "--no-deps" },
					},
					procMacro = {
						enable = true,
						ignored = {
							["async-trait"] = { "async_trait" },
							["napi-derive"] = { "napi" },
							["async-recursion"] = { "async_recursion" },
						},
					},
				},
			},
		},
	},
	config = function(_, opts)
		vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
	end,
}

plugins["crates"] = {
	"Saecki/crates.nvim",
	event = { "BufRead Cargo.toml" },
	opts = {
		src = {
			cmp = { enabled = true },
		},
	},
}

--json
plugins["SchemaStore"] = {
	"b0o/SchemaStore.nvim",
	lazy = true,
	version = false, -- last release is way too old
}

return plugins
