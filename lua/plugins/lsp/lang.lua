local config = require("plugins.conf")
local symbols = require("lib.symbols")
local lsp_lib = require("lib.lsp")
local pdf = require("lib.pdf")
local plugins = {}

-- ts
plugins["nvim-ts-autotag"] = {
	"windwp/nvim-ts-autotag",
	ft = config.autotag_ft,
	opts = function()
		local filetypes = {}
		for _, ft in pairs(config.autotag_ft) do
			filetypes[ft] = {
				enable_close = true,
			}
		end
		return {
			per_filetype = filetypes,
		}
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
				lsp_lib.key_attach(bufnr)
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
		completion = {
			cmp = { enabled = true },
		},
	},
}

-- json
plugins["SchemaStore"] = {
	"b0o/SchemaStore.nvim",
	lazy = true,
	version = false, -- last release is way too old
}

-- markdown
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

-- c/cpp
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
				type = symbols.Type,
				declaration = symbols.Declaration,
				expression = symbols.Circle,
				specifier = symbols.ListTree,
				statement = symbols.SymbolEvent,
				["template argument"] = symbols.Template,
			},
			kind_icons = {
				Compound = symbols.Namespace,
				Recovery = symbols.Error,
				TranslationUnit = symbols.CodeFile,
				PackExpansion = symbols.Ellipsis,
				TemplateTypeParm = symbols.Template,
				TemplateTemplateParm = symbols.Template,
				TemplateParamObject = symbols.Template,
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

-- tex
plugins["vimtex"] = {
	"lervag/vimtex",
	ft = "tex",
	config = function()
		vim.g.vimtex_view_automatic = 0
		vim.g.vimtex_quickfix_open_on_warning = 0
		vim.g.vimtex_quickfix_method = vim.fn.executable("pplatex") == 1 and "pplatex" or "latexlog"
		vim.api.nvim_create_autocmd("User", {
			once = true,
			pattern = "Load",
			callback = pdf.server_setup,
		})
	end,
}

-- lua
plugins["luvit-meta"] = {
	"Bilal2453/luvit-meta",
	lazy = true,
}

plugins["lazydev"] = {
	"folke/lazydev.nvim",
	ft = "lua",
	opts = {
		library = {
			{ path = "luvit-meta/library", words = { "vim%.uv" } },
		},
	},
}

return plugins
