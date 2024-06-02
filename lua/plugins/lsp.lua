local symbols = require("symbols")
local utils = require("utils")

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

local mason = {
	packages = {
		"tree-sitter-cli",
	},
}

lsp.treesitter = {
	"c",
	"c_sharp",
	"cpp",
	"cmake",
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
	"markdown",
	"bibtex",
	"markdown_inline",
	"latex",
}

lsp._default_config = function()
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
end

lsp.config = {
	lua_ls = function()
		local runtime_path = vim.split(package.path, ";")
		table.insert(runtime_path, "lua/?.lua")
		table.insert(runtime_path, "lua/?/init.lua")
		return vim.tbl_extend("force", lsp._default_config(), {
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
	["omnisharp"] = function()
		return vim.tbl_extend("force", lsp._default_config(), {
			cmd = {
				"dotnet",
				vim.fn.stdpath("data") .. "/mason/packages/omnisharp/libexec/Omnisharp.dll",
			},
			on_attach = function(client, bufnr)
				client.server_capabilities.semanticTokensProvider = nil
				lsp._default_config().on_attach(client, bufnr)
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
	["tsserver"] = function()
		return {
			single_file_support = true,
			capabilities = require("cmp_nvim_lsp").default_capabilities(),
			flags = lsp.flags,
			on_attach = function(client, bufnr)
				if #vim.lsp.get_clients({ name = "denols" }) > 0 then
					client.stop()
				else
					lsp.disableFormat(client)
					lsp._default_config().on_attach(client, bufnr)
				end
			end,
		}
	end,
	["emmet_ls"] = function()
		return {
			filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less" },
		}
	end,
	["clangd"] = function()
		local default = lsp._default_config()
		return vim.tbl_extend("force", default, {
			on_attach = function(client, bufnr)
				default.on_attach(client, bufnr)
				lsp.keyAttach(bufnr, {
					{ "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", "n", "Switch Source/Header (C/C++)" },
				})
			end,
			root_dir = function(fname)
				return require("lspconfig.util").root_pattern(
					"Makefile",
					"configure.ac",
					"configure.in",
					"config.h.in",
					"meson.build",
					"meson_options.txt",
					"build.ninja"
				)(fname) or require("lspconfig.util").root_pattern("compile_commands.json", "compile_flags.txt")(
					fname
				) or require("lspconfig.util").find_git_ancestor(fname)
			end,
			capabilities = {
				offsetEncoding = { "utf-16" },
			},
			cmd = {
				"clangd",
				"--background-index",
				"--clang-tidy",
				"--header-insertion=iwyu",
				"--completion-style=detailed",
				"--function-arg-placeholders",
				"--fallback-style=llvm",
			},
			init_options = {
				usePlaceholders = true,
				completeUnimported = true,
				clangdFileStatus = true,
			},
		})
	end,
	["pyright"] = lsp._default_config,
	["jsonls"] = function()
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
	texlab = function()
		local default = lsp._default_config()
		return vim.tbl_extend("force", default, {
			on_attach = function(client, bufnr)
				default.on_attach(client, bufnr)
				lsp.keyAttach(bufnr, {
					{ "<leader>lp", "<plug>(vimtex-view)", "n", "Vimtex preview" },
					{ "<leader>ll", "<plug>(vimtex-compile)", "n", "Vimtex compile" },
					{ "<leader>ld", "<plug>(vimtex-doc-package)", "n", "Vimtex Docs" },
				})
			end,
		})
	end,
	["bashls"] = lsp._default_config,
	["marksman"] = lsp._default_config,
	["neocmake"] = lsp._default_config,
}

lsp.mergeKeybindings = function(newKeybindings)
	return vim.tbl_extend("force", lsp.defaultKeybindings, newKeybindings)
end

lsp.keyAttach = function(buffer, keybindings)
	for _, binding in pairs(keybindings) do
		local modes = vim.split(binding[3] or "n", ",") -- 默认模式为普通模式
		local _, err = pcall(
			vim.keymap.set,
			modes,
			binding[1],
			binding[2],
			{ noremap = true, silent = true, buffer = buffer, desc = binding[4] }
		)
		if err then
			vim.notify(err, vim.log.levels.ERROR)
			return
		end
	end
end

local formatter = {}

formatter.ft = {
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
	["graphql"] = { "prettier" },
	["handlebars"] = { "prettier" },
	javascript = { { "prettierd", "prettier" } },
	cs = { "clang-format" },
	c = { "clang-format" },
	cpp = { "clang-format" },
	cmake = { "cmakelang" },
	["markdown"] = { { "prettierd", "prettier" }, "markdownlint", "markdown-toc" },
	["markdown.mdx"] = { { "prettierd", "prettier" }, "markdownlint", "markdown-toc" },
}

formatter.config = {
	shfmt = {
		prepend_args = { "-i", "2" },
	},
	["clang-format"] = {
		prepend_args = function(_, ctx)
			local file = vim.fs.find(".clang-format", { upward = true, path = ctx.dirname })[1]
			if not file then
				file = utils.config_root .. "/.clang-format"
			end

			return {
				"-style=file:" .. file,
			}
		end,
	},
}

local plugins = {}

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

plugins["nvim-lspconfig"] = {
	"neovim/nvim-lspconfig",
	event = "User Load",
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
	},
	config = function(_, opts)
		for k, v in pairs(lsp.config) do
			if string.sub(k, 1, 1) ~= "_" then
				require("lspconfig")[k].setup(v())
			end
		end
		vim.api.nvim_command("LspStart")
	end,
}

plugins["mason-lspconfig"] = {
	"williamboman/mason-lspconfig.nvim",
	lazy = true,
	opts = {
		ensure_installed = vim.tbl_extend("keep", table.keys(lsp.config), mason.packages),
	},
}

plugins["mason"] = {
	"williamboman/mason.nvim",
	event = "User Load",
	cmd = "Mason",
	keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
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
			for _, tool in ipairs(mason.packages) do
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
plugins["nvim-autopairs"] = {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	main = "nvim-autopairs",
	opts = {},
}

plugins["LuaSnip"] = {
	"L3MON4D3/LuaSnip",
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
	keys = {
		{
			"<Tab>",
			function()
				return vim.snippet.active({ direction = 1 }) and "<cmd>lua vim.snippet.jump(1)<cr>" or "<Tab>"
			end,
			expr = true,
			silent = true,
			mode = { "i", "s" },
		},
		{
			"<S-Tab>",
			function()
				return vim.snippet.active({ direction = -1 }) and "<cmd>lua vim.snippet.jump(-1)<cr>" or "<Tab>"
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

plugins["mini-surround"] = {
	"echasnovski/mini.surround",
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
		formatters_by_ft = formatter.ft,
		-- Set up format-on-save
		format_on_save = { timeout_ms = 500, lsp_fallback = true },
		-- Customize formatters
		formatters = formatter.config,
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

plugins["markdown-preview"] = {
	"iamcco/markdown-preview.nvim",
	cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
	build = function()
		vim.fn["mkdp#util#install"]()
	end,
	keys = {
		{
			"<leader>mp",
			ft = "markdown",
			"<cmd>MarkdownPreviewToggle<cr>",
			desc = "Markdown Preview",
		},
	},
	config = function()
		vim.cmd([[do FileType]])
		vim.g.mkdp_auto_close = 0
	end,
}

plugins["headlines"] = {
	"lukas-reineke/headlines.nvim",
	opts = function()
		local opts = {}
		for _, ft in ipairs({ "markdown", "norg", "rmd", "org" }) do
			opts[ft] = {
				headline_highlights = {},
				-- disable bullets for now. See https://github.com/lukas-reineke/headlines.nvim/issues/66
				bullets = {},
			}
			for i = 1, 6 do
				local hl = "Headline" .. i
				vim.api.nvim_set_hl(0, hl, { link = "Headline", default = true })
				table.insert(opts[ft].headline_highlights, hl)
			end
		end
		return opts
	end,
	ft = { "markdown", "norg", "rmd", "org" },
	config = function(_, opts)
		-- PERF: schedule to prevent headlines slowing down opening a file
		vim.schedule(function()
			require("headlines").setup(opts)
			require("headlines").refresh()
		end)
	end,
}

plugins["clangd_extensions"] = {
	"p00f/clangd_extensions.nvim",
	lazy = true,
	ft = "c",
	config = function() end,
	opts = {
		inlay_hints = {
			inline = false,
		},
		ast = {
			--These require codicons (https://github.com/microsoft/vscode-codicons)
			role_icons = {
				type = "",
				declaration = "",
				expression = "",
				specifier = "",
				statement = "",
				["template argument"] = "",
			},
			kind_icons = {
				Compound = "",
				Recovery = "",
				TranslationUnit = "",
				PackExpansion = "",
				TemplateTypeParm = "",
				TemplateTemplateParm = "",
				TemplateParamObject = "",
			},
		},
	},
}

plugins["cmake-tools"] = {
	"Civitasv/cmake-tools.nvim",
	dependencies = {
		"akinsho/toggleterm.nvim",
	},
	lazy = true,
	ft = { "cmake", "c" },
	opts = {
		cmake_runner = {
			name = "toggleterm",
		},
	},
}

plugins["nvim-dap"] = {
	"mfussenegger/nvim-dap",
	recommended = true,
	desc = "Debugging support. Requires language specific adapters to be configured. (see lang extras)",
	dependencies = {

		-- fancy UI for the debugger
		{
			"rcarriga/nvim-dap-ui",
			dependencies = { "nvim-neotest/nvim-nio" },
            -- stylua: ignore
            keys = {
                { "<leader>du", function() require("dapui").toggle({ }) end, desc = "Dap UI" },
                { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },
            },
			opts = {},
			config = function(_, opts)
				local dap = require("dap")
				local dapui = require("dapui")
				dapui.setup(opts)
				---@diagnostic disable: undefined-field
				dap.listeners.after.event_initialized["dapui_config"] = function()
					dapui.open({})
				end
				dap.listeners.before.event_terminated["dapui_config"] = function()
					dapui.close({})
				end
				dap.listeners.before.event_exited["dapui_config"] = function()
					dapui.close({})
				end
				---@diagnostic enable: undefined-field
			end,
		},

		-- virtual text for the debugger
		{
			"theHamsta/nvim-dap-virtual-text",
			opts = {},
		},

		-- mason.nvim integration
		{
			"jay-babu/mason-nvim-dap.nvim",
			dependencies = "mason.nvim",
			cmd = { "DapInstall", "DapUninstall" },
			opts = {
				-- Makes a best effort to setup the various debuggers with
				-- reasonable debug configurations
				automatic_installation = true,

				-- You can provide additional configuration to the handlers,
				-- see mason-nvim-dap README for more information
				handlers = {},

				-- You'll need to check that you have the required things installed
				-- online, please don't ask me how to install them :)
				ensure_installed = {
					-- Update this to ensure that you have the debuggers for the langs you want
				},
			},
		},

		-- VsCode launch.json parser
		{
			"folke/neoconf.nvim",
		},
	},
	opts = function()
		---@diagnostic disable undefined-field
		local dap = require("dap")
		local mason_registry = require("mason-registry")
		local codelldb_root = mason_registry.get_package("codelldb"):get_install_path() .. "/extension/"
		local codelldb_path = codelldb_root .. "adapter/codelldb"
		local liblldb_path = codelldb_root .. "lldb/lib/liblldb.so"
		dap.adapters = {
			codelldb = {
				type = "server",
				port = "${port}",
				host = "127.0.0.1",
				executable = {
					command = codelldb_path,
					args = { "--liblldb", liblldb_path, "--port", "${port}" },
				},
			},
		}

		local codelldb_conf = {
			{
				type = "codelldb",
				request = "launch",
				name = "Launch file",
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
				cwd = "${workspaceFolder}",
			},
			{
				type = "codelldb",
				request = "attach",
				name = "Attach to process",
				pid = require("dap.utils").pick_process,
				cwd = "${workspaceFolder}",
			},
		}

		dap.configurations = {
			c = codelldb_conf,
			cpp = codelldb_conf,
		}

		---@diagnostic enable undefined-field
	end,
    -- stylua: ignore
    ---@diagnostic disable: undefined-field
    keys = {
        { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
        { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
        { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
        { "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
        { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
        { "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
        { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
        { "<leader>dj", function() require("dap").down() end, desc = "Down" },
        { "<leader>dk", function() require("dap").up() end, desc = "Up" },
        { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
        { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
        { "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
        { "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
        { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
        { "<leader>ds", function() require("dap").session() end, desc = "Session" },
        { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
        { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
    },
	---@diagnostic enable: undefined-field
	config = function() end,
}

plugins["vimtex"] = {
	"lervag/vimtex",
	ft = "tex",
	config = function()
		vim.g.vimtex_mappings_disable = { ["n"] = { "K" } } -- disable `K` as it conflicts with LSP hover
		vim.g.vimtex_quickfix_method = vim.fn.executable("pplatex") == 1 and "pplatex" or "latexlog"
	end,
}

return plugins
