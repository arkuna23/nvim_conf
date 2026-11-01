local config = {}

local php_lsp = "intelephense"

local languages = require("lib.languages")

-- lsp configs
config.lsp = function()
	local lsp_lib = require("lib.lsp")
	local util = require("lib.util")
	local conf = {
		lua_ls = lsp_lib.create_config({
			settings = {
				Lua = {
					runtime = {
						version = "LuaJIT",
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
			lang = "lua",
		}),
		["omnisharp"] = lsp_lib.create_config({
			on_attach = function(client, _)
				client.server_capabilities.semanticTokensProvider = nil
			end,
			settings = {
				FormattingOptions = { EnableEditorConfigSupport = true, OrganizeImports = false },
				MsBuild = { LoadProjectsOnDemand = false },
				RoslynExtensionsOptions = {
					EnableAnalyzersSupport = false,
					EnableImportCompletion = false,
					AnalyzeOpenDocumentsOnly = false,
				},
				Sdk = { IncludePrereleases = true },
			},
		}, {
			inherit_on_attach = true,
			lang = "c#",
		}),
		["emmet_ls"] = lsp_lib.create_config({
			filetypes = {
				"html",
				"typescriptreact",
				"javascriptreact",
				"css",
				"sass",
				"scss",
				"less",
			},
			init_options = {
				html = {
					options = {
						["bem.enabled"] = true,
					},
				},
			},
		}, { lang = "emmet" }),
		["clangd"] = lsp_lib.create_config({
			capabilities = {
				offsetEncoding = { "utf-16" },
			},
			filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
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
			keybindings = {
				{
					"<leader>ch",
					"<cmd>ClangdSwitchSourceHeader<cr>",
					"n",
					"Switch Source/Header (C/C++)",
				},
			},
			lang = "c/cpp",
		}),
		["ruff"] = lsp_lib.create_config({
			cmd_env = { RUFF_TRACE = "messages" },
			init_options = {
				settings = {
					logLevel = "error",
				},
			},
			on_attach = function(client, _)
				client.server_capabilities.hoverProvider = false
			end,
		}, {
			lang = "python",
		}),
		["pyright"] = lsp_lib.create_config({}, { lang = "python" }),
		["jsonls"] = lsp_lib.create_config(function()
			return {
				settings = {
					json = {
						schemas = require("schemastore").json.schemas({
							extra = {
								{
									description = "plugin switchs schema",
									fileMatch = { "plugins_loaded.json" },
									name = "plugins_loaded.json",
									url = vim.fn.stdpath("data") .. "/plug_schema.json",
								},
							},
						}),
						format = {
							enable = true,
						},
						validate = { enable = true },
					},
				},
			}
		end, {
			lang = "json",
		}),
		texlab = lsp_lib.create_config({}, {
			inherit_on_attach = true,
			keybindings = {
				{ "<leader>lv", "<plug>(vimtex-view)", "n", "Vimtex preview" },
				{ "<leader>lc", "<plug>(vimtex-compile)", "n", "Vimtex compile" },
				{ "<leader>ld", "<plug>(vimtex-doc-package)", "n", "Vimtex Docs" },
			},
			whichkey = {
				{ "<leader>l", group = "vimtex" },
			},
			lang = "tex",
		}),
		["bashls"] = lsp_lib.create_config({}, {
			lang = "bash",
		}),
		["marksman"] = lsp_lib.create_config({}, {
			whichkey = {
				{ "<leader>m", group = "markdown" },
				{ "<leader>mm", group = "markmap" },
			},
			lang = "markdown",
		}),
		["neocmake"] = lsp_lib.create_config({}, {
			lang = "cmake",
		}),
		["html"] = lsp_lib.create_config({}, { lang = "html" }),
		["cssls"] = lsp_lib.create_config({
			settings = {
				css = {
					lint = {
						unknownAtRules = "ignore",
					},
				},
			},
		}, {
			lang = "css",
		}),
		["biome"] = lsp_lib.create_config({
			filetypes = {
				"astro",
				"css",
				"graphql",
				"javascript",
				"javascriptreact",
				"json",
				"jsonc",
				"svelte",
				"typescript",
				"typescript.tsx",
				"typescriptreact",
				"vue",
			},
		}, {
			lang = "js",
		}),
		--["eslint"] = lsp_lib.create_config({
		--	settings = {
		--		workingDirectories = { mode = "auto" },
		--	},
		--}, {
		--	inherit_keybindings = false,
		--}),
		["ts_ls"] = lsp_lib.create_config(function()
			local volar_path = util.get_pkg_path(
				"vue-language-server",
				"node_modules/@vue/language-server",
				{ warn = false }
			)
			return {
				init_options = {
					plugins = {
						{
							name = "@vue/typescript-plugin",
							location = volar_path,
							languages = { "vue", "typescript", "javascript" },
						},
					},
					preferences = {
						importModuleSpecifierPreference = "shortest",
						-- other settings
					},
				},
				filetypes = {
					"javascript",
					"javascriptreact",
					"javascript.jsx",
					"typescript",
					"typescriptreact",
					"typescript.tsx",
					"vue",
				},
			}
		end, {
			lang = "js",
		}),
		["vue_ls"] = lsp_lib.create_config({}, { lang = "js" }),
		["taplo"] = lsp_lib.create_config({}, {
			lang = "toml",
		}),
		["tailwindcss"] = lsp_lib.create_config({
			filetypes_exclude = { "markdown" },
		}, {
			lang = "tailwind",
		}),
		["kotlin_language_server"] = lsp_lib.create_config({}, { lang = "kotlin" }),
		["zls"] = lsp_lib.create_config(function()
			return {
				settings = {
					enable_build_on_save = true,
					build_on_save_args = { "-fincremental" },
				},
			}
		end, {
			lang = "zig",
		}),
		["jdtls"] = lsp_lib.create_config({}, {
			lang = "java",
		}),
		["tinymist"] = lsp_lib.create_config({
			single_file_support = true,
		}, {
			lang = "typst",
		}),
		["gopls"] = lsp_lib.create_config({
			filetypes = { "go", "gomod", "gowork", "gotmpl" },
			settings = {
				gopls = {
					gofumpt = true,
					codelenses = {
						gc_details = false,
						generate = true,
						regenerate_cgo = true,
						run_govulncheck = true,
						test = true,
						tidy = true,
						upgrade_dependency = true,
						vendor = true,
					},
					hints = {
						assignVariableTypes = true,
						compositeLiteralFields = true,
						compositeLiteralTypes = true,
						constantValues = true,
						functionTypeParameters = true,
						parameterNames = true,
						rangeVariableTypes = true,
					},
					analyses = {
						nilness = true,
						unusedparams = true,
						unusedwrite = true,
						useany = true,
					},
					usePlaceholders = true,
					completeUnimported = true,
					staticcheck = true,
					directoryFilters = {
						"-.git",
						"-.vscode",
						"-.idea",
						"-.vscode-test",
						"-node_modules",
					},
					semanticTokens = true,
				},
			},
		}, {
			lang = "go",
		}),
	}

	conf[php_lsp] = lsp_lib.create_config({}, { lang = "php" })

	for name, lsp_conf in pairs(conf) do
		if not languages.enabled(lsp_conf.__language) then
			conf[name] = nil
		end
	end

	config.lsp = function()
		return conf
	end
	return config.lsp()
end
config.treesitter = {
	"kotlin",
	"java",
	"c",
	"c_sharp",
	"cpp",
	"cmake",
	"css",
	"html",
	"php",
	"javascript",
	"json",
	"json5",
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
	"rst",
	"markdown",
	"bibtex",
	"markdown_inline",
	"latex",
	"vue",
	"haskell",
	"zig",
	"typst",

	"go",
	"gomod",
	"gowork",
	"gosum",
}

local parser_languages = {
	c_sharp = "c#",
	cpp = "c/cpp",
	tsx = "js",
	vue = "js",
	ron = "rust",
	json5 = "json",
	jsonc = "json",
	markdown_inline = "markdown",
	latex = "tex",
	bibtex = "tex",
	ninja = "cmake",
	gomod = "go",
	gowork = "go",
	gosum = "go",
}
config.treesitter = vim.tbl_filter(function(parser)
	return parser == "vim" or languages.enabled(parser_languages[parser] or parser)
end, config.treesitter)
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

---@class MasonPackage: string[]
---@field lang string

---@type (string|MasonPackage)[]
local mason_packages = {
	{ "ktlint", lang = "kotlin" },
	"tree-sitter-cli",
	{ "stylua", lang = "lua" },
	{ "prettier", lang = { "js", "html", "css", "json", "markdown", "yaml" } },
	{ "biome", lang = { "js", "css", "json", "graphql" } },
	{ "cmakelang", "clang-format", lang = "c/cpp" },
	{ "isort", "black", lang = "python" },
	{
		"markdownlint",
		"markdown-toc",
		lang = "markdown",
	},
	{
		"phpcs",
		"php-cs-fixer",
		lang = "php",
	},
	{
		"haskell-language-server",
		"haskell-debug-adapter",
		lang = "haskell",
	},
	{
		"java-debug-adapter",
		"java-test",
		lang = "java",
	},
	{
		"typstyle",
		lang = "typst",
	},
	{
		"goimports",
		"gofumpt",
		"gomodifytags",
		"impl",
		"golangci-lint",
		"delve",
		lang = "go",
	},
}

-- mason configs
config.mason = {
	packages = function()
		local packages = {}
		for _, pkg in ipairs(mason_packages) do
			local ty = type(pkg)

			if ty == "table" then
				if not languages.enabled(pkg.lang) then
					goto continue
				end

				for _, value in ipairs(pkg) do
					table.insert(packages, value)
				end
			else
				table.insert(packages, pkg)
			end
			::continue::
		end

		config.mason.packages = function()
			return packages
		end

		return packages
	end,
}

config.formatter = function()
	local util = require("lib.util")
	local formatter = {}

	-- formatter filetypes
	local web = require("lib.format").web_formatters
	formatter.ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		javascript = web,
		javascriptreact = web,
		typescript = web,
		typescriptreact = web,
		css = web,
		json = web,
		jsonc = web,
		graphql = web,
		vue = { "prettier" },
		svelte = { "prettier" },
		astro = { "prettier" },
		scss = { "prettier" },
		less = { "prettier" },
		html = { "prettier" },
		yaml = { "prettier" },
		handlebars = { "prettier" },
		markdown = { "prettier" },
		["markdown.mdx"] = { "prettier" },
		cs = { "clang-format" },
		c = { "clang-format" },
		cpp = { "clang-format" },
		php = { "php_cs_fixer" },
		kotlin = { "ktlint" },
		zig = { "zigfmt" },
		typst = { "typstyle" },
		go = { "goimports", "gofumpt" },
	}

	---@diagnostic disable-next-line: undefined-doc-name
	--- @type table<string, conform.FormatterConfigOverride|fun(bufnr: integer): nil|conform.FormatterConfigOverride>
	formatter.config = {
		zigfmt = {
			command = "zig",
			args = { "fmt", "--stdin" },
			stdin = true,
		},
		shfmt = {
			prepend_args = { "-i", "2" },
		},
		["clang-format"] = {
			prepend_args = function(_, ctx)
				local file = vim.fs.find(
					".clang-format",
					{ upward = true, path = ctx.dirname, type = "file" }
				)[1]
				if not file then
					file = util.config_root() .. "/conf/.clang-format"
				end

				return {
					"-style=file:" .. file,
				}
			end,
		},
		biome = {
			require_cwd = true,
		},
		["prettier"] = {
			prepend_args = require("lib.format").prettier_args,
		},
	}

	formatter.format_on_save_exclude_ft = {
		"markdown",
		"vue",
		"kotlin",
	}

	config.formatter = function()
		return formatter
	end
	return config.formatter()
end

return config
