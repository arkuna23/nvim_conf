local config = {}

local php_lsp = "intelephense"

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
			setup = function(opts)
				local runtime_path = vim.split(package.path, ";")
				table.insert(runtime_path, "lua/?.lua")
				table.insert(runtime_path, "lua/?/init.lua")
				return opts
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
				)(fname) or require("lspconfig.util").root_pattern(
					"compile_commands.json",
					"compile_flags.txt"
				)(fname) or vim.fs.dirname(
					vim.fs.find(".git", { path = fname, upward = true })[1]
				)
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
				{
					"<leader>ch",
					"<cmd>ClangdSwitchSourceHeader<cr>",
					"n",
					"Switch Source/Header (C/C++)",
				},
			},
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
		}),
		["pyright"] = lsp_lib.create_config({
			root_dir = function()
				return (vim.loop or vim.uv).cwd()
			end,
		}),
		["jsonls"] = function()
			return {
				-- lazy-load schemastore when needed
				on_new_config = function(new_config)
					new_config.settings.json.schemas = new_config.settings.json.schemas or {}
					vim.list_extend(
						new_config.settings.json.schemas,
						require("schemastore").json.schemas()
					)
				end,
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
		end,
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
		}),
		["bashls"] = lsp_lib.create_config(),
		["marksman"] = lsp_lib.create_config({}, {
			whichkey = {
				{ "<leader>m", group = "markdown" },
				{ "<leader>mm", group = "markmap" },
			},
		}),
		["neocmake"] = lsp_lib.create_config(),
		["html"] = lsp_lib.create_config(),
		["cssls"] = lsp_lib.create_config({
			settings = {
				css = {
					lint = {
						unknownAtRules = "ignore",
					},
				},
			},
		}),
		["biome"] = lsp_lib.create_config({
			cmd = { "biome", "lsp-proxy" },
			single_file_support = false,
			root_dir = require("lspconfig.util").root_pattern("biome.json", "biome.jsonc"),
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
		}),
		--["eslint"] = lsp_lib.create_config({
		--	settings = {
		--		workingDirectories = { mode = "auto" },
		--	},
		--}, {
		--	inherit_keybindings = false,
		--}),
		["ts_ls"] = lsp_lib.create_config(function()
			local volar_path =
				util.get_pkg_path("vue-language-server", "node_modules/@vue/language-server")
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
		end),
		["taplo"] = lsp_lib.create_config(),
		["tailwindcss"] = lsp_lib.create_config({
			filetypes_exclude = { "markdown" },
		}),
		["hls"] = lsp_lib.create_config(),
		["kotlin_language_server"] = lsp_lib.create_config(function()
			return {
				root_dir = vim.fs.dirname(
					vim.fs.find({ "settings.gradle", "settings.gradle.kts" }, { upward = true })[1]
				),
			}
		end),
	}

	local php_lsp_opts = {
		root_dir = function()
			return (vim.loop or vim.uv).cwd()
		end,
	}

	if php_lsp == "intelephense" then
		conf.intelephense = lsp_lib.create_config(php_lsp_opts)
	elseif php_lsp == "phpactor" then
		conf.phpactor = lsp_lib.create_config(php_lsp_opts)
	end

	config.lsp = function()
		return conf
	end
	return config.lsp()
end
config.treesitter = {
	"kotlin",
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
	"rst",
	"markdown",
	"bibtex",
	"markdown_inline",
	"latex",
	"vue",
	"haskell",
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
		"ktlint",
		"tree-sitter-cli",
		"stylua",
		"prettier",
		"cmakelang",
		"clang-format",
		"isort",
		"markdownlint",
		"markdown-toc",
		"phpcs",
		"php-cs-fixer",
		"biome",
		"haskell-language-server",
		"haskell-debug-adapter",
	},
}

config.formatter = function()
	local util = require("lib.util")
	local formatter = {}

	-- formatter filetypes
	formatter.ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		["javascriptreact"] = { "biome" },
		["typescriptreact"] = { "biome" },
		["vue"] = { "biome" },
		["css"] = { "biome" },
		["scss"] = { "biome" },
		["less"] = { "biome" },
		["html"] = { "biome" },
		["json"] = { "biome" },
		["jsonc"] = { "biome" },
		["yaml"] = { "biome" },
		["graphql"] = { "biome" },
		["handlebars"] = { "biome" },
		javascript = { "biome" },
		typescript = { "biome" },
		cs = { "clang-format" },
		c = { "clang-format" },
		cpp = { "clang-format" },
		cmake = { "cmakelang" },
		["markdown"] = { "biome", "markdownlint", "markdown-toc", stop_after_first = true },
		["markdown.mdx"] = { "biome", "markdownlint", "markdown-toc", stop_after_first = true },
		php = { "php_cs_fixer" },
		kotlin = { "ktlint" },
	}

	---@diagnostic disable-next-line: undefined-doc-name
	--- @type table<string, conform.FormatterConfigOverride|fun(bufnr: integer): nil|conform.FormatterConfigOverride>
	formatter.config = {
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
				}

				for _, file in ipairs(config_files) do
					local matches =
						vim.fs.find(file, { upward = true, path = ctx.dirname, type = "file" })
					if #matches > 0 then
						return {}
					end
				end

				-- check package.json
				local json_path = vim.fs.find(
					"package.json",
					{ upward = true, path = ctx.dirname, type = "file" }
				)[1]
				if json_path then
					local json = util.read_file(json_path)
					if json then
						local content = vim.json.decode(json)
						if content.prettier then
							return {}
						end
					else
						vim.notify("cannot read " .. json_path, vim.log.levels.ERROR)
					end
				end

				return {
					"--config",
					util.config_root() .. "/conf/.prettierrc.json",
				}
			end,
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
