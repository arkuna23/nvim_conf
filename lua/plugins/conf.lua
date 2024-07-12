local lsp_lib = require("lib.lsp")
local pdf = require("lib.pdf")
local util = require("lib.util")

local config = {}

-- lsp configs
config.lsp = {
	lua_ls = lsp_lib.create_config({
		settings = {
			Lua = {
				runtime = {
					version = "LuaJIT",
					---@diagnostic disable-next-line: undefined-global
					path = runtime_path,
				},
				diagnostics = {
					globals = { "vim" },
				},
				workspace = {
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
	}, {
		extra = function()
			local runtime_path = vim.split(package.path, ";")
			table.insert(runtime_path, "lua/?.lua")
			table.insert(runtime_path, "lua/?/init.lua")
		end,
	}),
	["omnisharp"] = lsp_lib.create_config({
		cmd = {
			"dotnet",
			vim.fn.stdpath("data") .. "/mason/packages/omnisharp/libexec/Omnisharp.dll",
		},
		on_attach = function(client, _)
			client.server_capabilities.semanticTokensProvider = nil
		end,
		enable_editorconfig_support = true,
		enable_ms_build_load_projects_on_demand = false,
		enable_roslyn_analyzers = false,
		organize_imports_on_format = false,
		enable_import_completion = false,
		sdk_include_prereleases = true,
		analyze_open_documents_only = false,
	}, {
		inherit_on_attach = true,
	}),
	["emmet_ls"] = lsp_lib.create_config({
		filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less" },
		init_options = {
			html = {
				options = {
					["bem.enabled"] = true,
				},
			},
		},
	}),
	["clangd"] = lsp_lib.create_config({
		root_dir = function(fname)
			return require("lspconfig.util").root_pattern(
				"Makefile",
				"configure.ac",
				"configure.in",
				"config.h.in",
				"meson.build",
				"meson_options.txt",
				"build.ninja"
			)(fname) or require("lspconfig.util").root_pattern("compile_commands.json", "compile_flags.txt")(fname) or require(
				"lspconfig.util"
			).find_git_ancestor(fname)
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
	}, {
		inherit_on_attach = true,
		keybindings = {
			{ "<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", "n", "Switch Source/Header (C/C++)" },
		},
		whichkey = {
			["<leader>c"] = { name = "+clangd" },
		},
	}),
	["pyright"] = lsp_lib.create_config(),
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
	texlab = lsp_lib.create_config({}, {
		inherit_on_attach = true,
		keybindings = {
			{ "<leader>ll", pdf.latex_preview, "n", "Vimtex preview" },
			{ "<leader>lc", "<plug>(vimtex-compile)", "n", "Vimtex compile" },
			{ "<leader>ld", "<plug>(vimtex-doc-package)", "n", "Vimtex Docs" },
		},
		whichkey = {
			["<leader>l"] = { name = "+vimtex" },
		},
	}),
	["bashls"] = lsp_lib.create_config(),
	["marksman"] = lsp_lib.create_config({
		on_attach = function(_, bufnr)
			require("which-key").register({
				["<leader>m"] = { name = "+markdown" },
			}, {
				buffer = bufnr,
			})
		end,
	}),
	["neocmake"] = lsp_lib.create_config(),
	["html"] = lsp_lib.create_config(),
	["cssls"] = lsp_lib.create_config(),
	volar = lsp_lib.create_config(function()
		return {
			init_options = {
				typescript = {
					tsdk = util.get_pkg_path("typescript-language-server", "node_modules/typescript/lib"),
				},
			},
		}
	end),
	["eslint"] = lsp_lib.create_config({
		settings = {
			workingDirectories = { mode = "auto" },
		},
	}, {
		inherit_keybindings = false,
	}),
	["tsserver"] = lsp_lib.create_config(function()
		local volar_path = util.get_pkg_path("vue-language-server", "node_modules/@vue/language-server")
		return {
			init_options = {
				plugins = {
					{
						name = "@vue/typescript-plugin",
						location = volar_path,
						languages = { "vue", "typescript", "javascript" },
					},
				},
			},
			filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
		}
	end),
	["taplo"] = lsp_lib.create_config(),
}

config.treesitter = {
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
	"vue",
}

-- autotag filetypes
config.autotag_ft = {
	"html",
	"jsx",
	"vue",
	"markdown",
	"php",
	"tsx",
	"xml",
	"typescript",
	"javascript",
}

-- mason configs
config.mason = {
	packages = {
		"tree-sitter-cli",
		"stylua",
		"prettier",
		"cmakelang",
		"clang-format",
		"isort",
		"markdownlint",
		"markdown-toc",
	},
}

local formatter = {}

-- formatter filetypes
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
	typescript = { { "prettierd", "prettier" } },
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
			local file = vim.fs.find(".clang-format", { upward = true, path = ctx.dirname, type = "file" })[1]
			if not file then
				file = util.config_root .. "/.clang-format"
			end

			return {
				"-style=file:" .. file,
			}
		end,
	},
	["prettier"] = {
		prepend_args = function(_, ctx)
			local config_files = {
				".prettierrc",
				".prettierrc.yaml",
				".prettierrc.yml",
				".prettierrc.json",
				".prettierrc.toml",
				"prettier.config.js",
				".prettierrc.js",
				"package.json",
			}

			for _, file in ipairs(config_files) do
				local matches = vim.fs.find(file, { upward = true, path = ctx.dirname, type = "file" })
				if #matches > 0 then
					return {}
				end
			end

			return {
				"--config",
				util.config_root .. "/.prettierrc.json",
			}
		end,
	},
}
formatter.format_on_save_exclude_ft = {
	"markdown",
	"vue",
}
config.formatter = formatter

return config
