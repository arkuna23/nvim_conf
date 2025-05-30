---@type table<string, PlugSpec>
local plugins = {}

-- ts
plugins["nvim-ts-autotag"] = {
	"windwp/nvim-ts-autotag",
	categories = { "lang", "html" },
	ft = function()
		return require("plugins.conf").autotag_ft
	end,
	opts = function()
		local filetypes = {}
		for _, ft in pairs(require("plugins.conf").autotag_ft) do
			filetypes[ft] = {
				enable_close = true,
			}
		end
		return {
			per_filetype = filetypes,
		}
	end,
}

-- css
plugins["tailwindcss-colorizer-cmp"] = {
	"roobert/tailwindcss-colorizer-cmp.nvim",
	categories = { "lang", "tailwindcss" },
	ft = { "css", "scss", "sass", "html", "js", "jsx", "ts", "tsx" },
	-- optionally, override the default options:
	config = function()
		require("tailwindcss-colorizer-cmp").setup({
			color_square_width = 2,
		})
	end,
}

-- rust
plugins["rustaceanvim"] = {
	"mrcjkb/rustaceanvim",
	categories = { "lang", "rust" },
	version = "^5", -- Recommended
	ft = { "rust" },
	build = "rustup component add rust-analyzer",
	opts = function()
		return {
			server = {
				on_attach = function(_, bufnr)
					require("lib.lsp").key_attach(bufnr)
				end,
				default_settings = {
					-- rust-analyzer language server configuration
					["rust-analyzer"] = {
						cargo = {
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
		}
	end,
	config = function(_, opts)
		vim.g.rustaceanvim = vim.tbl_deep_extend("force", vim.g.rustaceanvim or {}, opts or {})
	end,
}

-- haskell
plugins["crates"] = {
	"Saecki/crates.nvim",
	categories = { "lang", "rust" },
	event = { "BufRead Cargo.toml" },
	opts = {
		completion = {
			cmp = { enabled = true },
		},
	},
}

plugins["haskell-tools"] = {
	"mrcjkb/haskell-tools.nvim",
	version = "^3",
	categories = { "lang", "haskell" },
	ft = { "haskell", "lhaskell", "cabal", "cabalproject" },
	dependencies = {
		{ "nvim-telescope/telescope.nvim", optional = true },
	},
	config = function()
		local ok, telescope = pcall(require, "telescope")
		if ok then
			telescope.load_extension("ht")
		end
	end,
}

plugins["neotest-haskell"] = { "mrcjkb/neotest-haskell", categories = { "lang", "haskell" } }

plugins["haskell-snippets"] = {
	"mrcjkb/haskell-snippets.nvim",
	dependencies = { "L3MON4D3/LuaSnip" },
	categories = { "lang", "haskell" },
	ft = { "haskell", "lhaskell", "cabal", "cabalproject" },
	config = function()
		local haskell_snippets = require("haskell-snippets").all
		require("luasnip").add_snippets("haskell", haskell_snippets, { key = "haskell" })
	end,
}

plugins["telescope_hoogle"] = {
	"luc-tielen/telescope_hoogle",
	ft = { "haskell", "lhaskell", "cabal", "cabalproject" },
	categories = { "lang", "haskell" },
	dependencies = {
		{ "nvim-telescope/telescope.nvim" },
	},
	config = function()
		local ok, telescope = pcall(require, "telescope")
		if ok then
			telescope.load_extension("hoogle")
		end
	end,
}

-- json
plugins["SchemaStore"] = {
	"b0o/SchemaStore.nvim",
	categories = { "lang", "json" },
	lazy = true,
	version = false, -- last release is way too old
}

-- markdown
plugins["markdown-preview"] = {
	"iamcco/markdown-preview.nvim",
	categories = { "lang", "markdown" },
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
	categories = { "lang", "markdown" },
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

plugins["markmap"] = {
	"Zeioth/markmap.nvim",
	categories = { "lang", "markdown", "markmap" },
	build = "yarn global add markmap-cli",
	cmd = { "MarkmapOpen", "MarkmapSave", "MarkmapWatch", "MarkmapWatchStop" },
	keys = {
		{
			"<leader>mmo",
			ft = "markdown",
			"<cmd>MarkmapOpen<cr>",
			desc = "Markmap Open Preview",
		},
		{
			"<leader>mms",
			ft = "markdown",
			"<cmd>MarkmapSave<cr>",
			desc = "Markmap Save",
		},
		{
			"<leader>mmw",
			ft = "markdown",
			"<cmd>MarkmapWatch<cr>",
			desc = "Markmap Watch",
		},
		{
			"<leader>mmt",
			ft = "markdown",
			"<cmd>MarkmapWatchStop<cr>",
			desc = "Markmap Stop Watch",
		},
	},
	opts = {
		html_output = "/tmp/markmap.html",
		hide_toolbar = false,
		grace_period = 3600000,
	},
	config = function(_, opts)
		require("markmap").setup(opts)
	end,
}

-- c/cpp
plugins["clangd_extensions"] = {
	"p00f/clangd_extensions.nvim",
	categories = { "lang", "c/cpp" },
	lazy = true,
}

plugins["cmake-tools"] = {
	"Civitasv/cmake-tools.nvim",
	categories = { "lang", "c/cpp" },
	dependencies = {
		"akinsho/toggleterm.nvim",
	},
	lazy = true,
	ft = { "cmake", "c", "cpp" },
	opts = {
		cmake_runner = {
			name = "toggleterm",
		},
	},
}

-- tex
plugins["vimtex"] = {
	"lervag/vimtex",
	categories = { "lang", "tex" },
	ft = "tex",
	config = function()
		vim.g.vimtex_view_method = "zathura"
		vim.g.vimtex_quickfix_open_on_warning = 0
		vim.g.vimtex_quickfix_method = vim.fn.executable("pplatex") == 1 and "pplatex" or "latexlog"
		--vim.api.nvim_create_autocmd("User", {
		--	once = true,
		--	pattern = "Load",
		--	callback = require("lib.pdf").server_setup,
		--})
	end,
}

-- lua
plugins["lazydev"] = {
	"folke/lazydev.nvim",
	categories = { "lang", "lua" },
	ft = "lua",
	dependencies = {
		"Bilal2453/luvit-meta",
	},
	opts = {
		library = {
			{ path = "luvit-meta/library", words = { "vim%.uv" } },
		},
	},
}

return plugins
