local root = vim.fn.getcwd()
vim.opt.rtp:prepend(root)
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/site")
for _, name in ipairs({
	"nvim-lspconfig",
	"cmp-nvim-lsp",
	"neoconf.nvim",
	"conform.nvim",
	"nvim-treesitter",
	"nvim-dap",
	"plenary.nvim",
}) do
	vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/" .. name)
end
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
require("lib.user_config").editor_lang = nil

local temporary = vim.fn.tempname()
vim.fn.mkdir(temporary, "p")
local function fixture(path, text)
	local file = temporary .. "/" .. path
	vim.fn.mkdir(vim.fs.dirname(file), "p")
	vim.fn.writefile(vim.split(text, "\n"), file)
	return file
end
local function buffer(file, filetype, lines)
	local buf = vim.api.nvim_create_buf(true, false)
	vim.api.nvim_set_current_buf(buf)
	vim.api.nvim_buf_set_name(buf, file)
	vim.bo[buf].filetype = filetype
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines or vim.fn.readfile(file))
	return buf
end

local function check()
	local languages = require("lib.languages")
	local user = require("lib.user_config")
	local original = user.editor_lang
	user.editor_lang = { "js/ts", "cpp" }
	assert(languages.enabled("js") and languages.enabled("c/cpp"))
	user.editor_lang = original

	require("neoconf").setup({ live_reload = false, plugins = { lspconfig = { enabled = false } } })
	local specs = require("plugins.conf").lsp()
	assert(specs.gopls().settings.gopls.staticcheck)
	assert(specs.vue_ls and specs.intelephense)
	for _, project in ipairs({ "first", "second" }) do
		fixture(project .. "/.luarc.json", "{}")
		fixture(
			project .. "/.neoconf.json",
			vim.json.encode({
				lspconfig = { lua_ls = { ["Lua.runtime.special"] = { project = project } } },
			})
		)
		local file = fixture(project .. "/main.lua", "return 42")
		local buf = buffer(file, "lua")
		vim.lsp.config("lua_ls", specs.lua_ls())
		local config = vim.lsp.config.lua_ls
		local wrapped = require("lib.project_lsp").wrap("lua_ls", config)
		local directory
		wrapped.root_dir(buf, function(value)
			directory = value
		end)
		assert(directory == temporary .. "/" .. project)
		local client = { root_dir = directory, settings = config.settings }
		wrapped.before_init({}, client)
		assert(client.settings.Lua.runtime.special.project == project)
	end
	print("PASS: language aliases and independent project roots/settings")

	local options = require("plugins.conf").formatter()
	local conform = require("conform")
	conform.setup({
		formatters_by_ft = options.ft,
		formatters = options.config,
		default_format_opts = { lsp_format = "fallback" },
	})
	fixture("biome/biome.json", "{}")
	local biome = buffer(fixture("biome/main.ts", "const value=1"), "typescript")
	assert(require("lib.format").web_formatters(biome)[1] == "biome")
	fixture("prettier/.prettierrc.cjs", "module.exports = { singleQuote: true };")
	local prettier_file = fixture("prettier/main.ts", 'const value="hello"')
	local prettier = buffer(prettier_file, "typescript")
	assert(require("lib.format").web_formatters(prettier)[1] == "prettier")
	conform.format({ bufnr = prettier })
	assert(vim.api.nvim_buf_get_lines(prettier, 0, -1, false)[1] == "const value = 'hello';")
	local plain = buffer(fixture("plain/main.json", '{"hello":1}'), "json", { '{"hello":1}' })
	local config = conform.get_formatter_config("prettier", plain)
	local context = require("conform.runner").build_context(plain, config)
	local args = require("lib.format").prettier_args(config, context)
	assert(args[1] == "--config" and args[2] == root .. "/conf/.prettierrc.json")
	assert(options.ft.scss[1] == "prettier" and options.ft.yaml[1] == "prettier")
	print("PASS: project formatter selection and Prettier configuration")

	local source = { "local function greet()", '  local text = "你好"', "  return text", "end" }
	local buf = buffer(fixture("selection.lua", table.concat(source, "\n")), "lua", source)
	local ts = require("lib.treesitter")
	ts.setup({ "lua" })
	vim.treesitter.get_parser(buf):parse()
	vim.api.nvim_win_set_cursor(0, { 2, 16 })
	local function selected()
		return table.concat(
			vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = "v" }),
			"\n"
		)
	end
	ts.select("expand")
	local first = selected()
	assert(first == "你好", vim.inspect(first))
	ts.select("expand")
	assert(#selected() > #first)
	ts.select("shrink")
	assert(selected() == first)
	ts.select("scope")
	assert(selected():find("local function greet", 1, true))
	assert(vim.bo[buf].indentexpr == "v:lua.require'nvim-treesitter'.indentexpr()")
	assert(vim.wo.foldmethod == "expr")
	print("PASS: Unicode syntax selection, expansion, scope and history")

	local dap = require("dap")
	local go = { { name = "Existing Go", type = "go", request = "launch" } }
	dap.adapters.go = { type = "executable", command = "dlv" }
	dap.configurations.go = go
	local spec = require("plugins.dap")["nvim-dap"]
	spec.config()
	assert(dap.configurations.go == go and dap.adapters.go.command == "dlv")
	assert(dap.adapters.codelldb.executable.command:find("extension/adapter/codelldb", 1, true))
	local input, continue = vim.fn.input, dap.continue
	local original_config = { name = "Arguments", args = { "original" } }
	vim.fn.input = function()
		return 'hello "two words"'
	end
	dap.continue = function(opts)
		local configured = opts.before(original_config)
		assert(vim.deep_equal(configured.args, { "hello", "two words" }))
		assert(original_config.args[1] == "original")
	end
	for _, key in ipairs(spec.keys) do
		if key[1] == "<leader>da" then
			key[2]()
		end
	end
	vim.fn.input, dap.continue = input, continue
	print("PASS: adapter preservation and quoted launch arguments")

	local connection, tty = vim.env.SSH_CONNECTION, vim.env.SSH_TTY
	local send = vim.api.nvim_ui_send
	local transmitted
	vim.api.nvim_ui_send = function(value)
		transmitted = value
	end
	vim.env.SSH_CONNECTION = "127.0.0.1 1000 127.0.0.1 22"
	dofile(root .. "/lua/config/general.lua")
	local clipboard = vim.g.clipboard
	clipboard.copy["+"]({ "remote copy" }, "v")
	assert(transmitted:find(vim.base64.encode("remote copy"), 1, true))
	assert(vim.deep_equal(clipboard.paste["+"](), { { "remote copy" }, "v" }))
	vim.api.nvim_ui_send = send
	vim.env.SSH_CONNECTION, vim.env.SSH_TTY = nil, nil
	dofile(root .. "/lua/config/general.lua")
	assert(vim.tbl_contains(vim.opt.clipboard:get(), "unnamedplus"))
	vim.env.SSH_CONNECTION, vim.env.SSH_TTY = connection, tty
	print("PASS: SSH clipboard transport/cache and desktop clipboard selection")
end

local ok, err = xpcall(check, debug.traceback)
vim.fn.delete(temporary, "rf")
if not ok then
	error(err)
end
print("All configuration checks passed")
