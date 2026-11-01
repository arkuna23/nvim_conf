local root = vim.fn.getcwd()
vim.opt.rtp:prepend(root)
vim.o.hidden = true
vim.opt.rtp:append(vim.fn.stdpath("data") .. "/site")
for _, name in ipairs({
	"nvim-lspconfig",
	"cmp-nvim-lsp",
	"neoconf.nvim",
	"conform.nvim",
	"which-key.nvim",
	"nvim-dap",
	"plenary.nvim",
	"rustaceanvim",
}) do
	vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/" .. name)
end
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
require("lib.user_config").editor_lang = nil
require("neoconf").setup({ live_reload = false, plugins = { lspconfig = { enabled = false } } })
require("which-key").setup({})
local directory = vim.fn.tempname()
vim.fn.mkdir(directory, "p")
local function file(path, text)
	local name = directory .. "/" .. path
	vim.fn.mkdir(vim.fs.dirname(name), "p")
	vim.fn.writefile(vim.split(text, "\n"), name)
	return name
end
local function open(path, ft)
	vim.cmd.edit(vim.fn.fnameescape(path))
	vim.bo.filetype = ft
	return vim.api.nvim_get_current_buf()
end
local function attached(buf, names)
	assert(
		vim.wait(60000, function()
			for _, name in ipairs(names) do
				local client = vim.lsp.get_clients({ bufnr = buf, name = name })[1]
				if not client or not client.initialized then
					return false
				end
			end
			return true
		end, 50),
		"LSP attachment timed out: " .. table.concat(names, ", ")
	)
end

local function check()
	local specs = require("plugins.conf").lsp()
	local project = require("lib.project_lsp")
	for _, name in ipairs({ "lua_ls", "intelephense", "gopls", "ts_ls", "vue_ls", "taplo" }) do
		vim.lsp.config(name, specs[name]())
		vim.lsp.config(name, project.wrap(name, vim.lsp.config[name]))
		vim.lsp.enable(name)
	end
	for _, name in ipairs({ "one", "two" }) do
		file(name .. "/.luarc.json", "{}")
		local buf = open(file(name .. "/main.lua", "return 42"), "lua")
		attached(buf, { "lua_ls" })
		assert(
			vim.lsp.get_clients({ bufnr = buf, name = "lua_ls" })[1].root_dir
				== directory .. "/" .. name
		)
	end
	print("PASS: actual Lua clients in two workspaces")

	file("php/composer.json", "{}")
	local php = open(file("php/main.php", "<?php\nfunction answer(): int { return 42; }\n"), "php")
	attached(php, { "intelephense" })
	file("go/go.mod", "module example.local/configcheck\n\ngo 1.24\n")
	local go =
		open(file("go/main.go", "package main\nfunc main() { value := 42; _ = value }\n"), "go")
	attached(go, { "gopls" })
	local rust_spec = require("plugins.lang").rustaceanvim
	rust_spec.config(nil, rust_spec.opts())
	file(
		"rust/Cargo.toml",
		'[package]\nname = "configcheck"\nversion = "0.1.0"\nedition = "2021"\n'
	)
	local rust = open(file("rust/src/main.rs", "fn main() { let _value = 42; }\n"), "rust")
	require("rustaceanvim.lsp").start()
	attached(rust, { "rust-analyzer" })
	print("PASS: PHP, Go and rustaceanvim language services")

	file("vue/package.json", '{"name":"configcheck","private":true}')
	local npm = {
		"npm",
		"install",
		"--ignore-scripts",
		"--no-audit",
		"--no-fund",
		"--no-package-lock",
		"vue@3",
	}
	local dependencies = vim.system(npm, { cwd = directory .. "/vue", text = true }):wait(120000)
	assert(dependencies.code == 0, dependencies.stderr)
	file("vue/pnpm-lock.yaml", "lockfileVersion: '9.0'\n")
	file("vue/tsconfig.json", '{"compilerOptions":{"target":"ES2022"},"include":["*.vue"]}')
	local vue_file = file(
		"vue/App.vue",
		'<script setup lang="ts">\nconst count = 1\nconst doubled = count * 2\n</script>\n<template><div>{{ doubled }}</div></template>\n'
	)
	local vue = open(vue_file, "vue")
	attached(vue, { "ts_ls", "vue_ls" })
	local ts = vim.lsp.get_clients({ bufnr = vue, name = "ts_ls" })[1]
	local hover = ts:request_sync("textDocument/hover", {
		textDocument = { uri = vim.uri_from_fname(vue_file) },
		position = { line = 2, character = 16 },
	}, 10000, vue)
	assert(hover and hover.result and hover.result.contents, "Vue script hover")
	local definition = ts:request_sync("textDocument/definition", {
		textDocument = { uri = vim.uri_from_fname(vue_file) },
		position = { line = 2, character = 16 },
	}, 10000, vue)
	assert(definition and definition.result and definition.result[1], "Vue script definition")
	local completions = vim.lsp.buf_request_sync(vue, "textDocument/completion", {
		textDocument = { uri = vim.uri_from_fname(vue_file) },
		position = { line = 4, character = 21 },
		context = { triggerKind = 1 },
	}, 10000)
	local labels = {}
	for _, response in pairs(completions or {}) do
		local result = response.result or {}
		for _, item in ipairs(result.items or result) do
			labels[item.label] = true
		end
	end
	assert(labels.doubled, "Vue template completion: " .. vim.inspect(completions))
	print("PASS: Vue hover, script definition and template completion")

	local config = require("plugins.conf").formatter()
	local conform = require("conform")
	conform.setup({
		formatters_by_ft = config.ft,
		formatters = config.config,
		default_format_opts = { lsp_format = "fallback", timeout_ms = 5000 },
	})
	local python = open(file("format/main.py", "import sys\nimport os\nx={'hello':1}\n"), "python")
	conform.format({ bufnr = python })
	local text = table.concat(vim.api.nvim_buf_get_lines(python, 0, -1, false), "\n")
	assert(text:find('x = {"hello": 1}', 1, true))
	assert(text:find("import os", 1, true) < text:find("import sys", 1, true))
	file("toml/.taplo.toml", "")
	local toml = open(file("toml/settings.toml", "hello={value=1}\n"), "toml")
	attached(toml, { "taplo" })
	conform.format({ bufnr = toml })
	assert(vim.api.nvim_buf_get_lines(toml, 0, 1, false)[1]:find("hello =", 1, true))
	print("PASS: Python formatter chain and TOML LSP fallback")

	local dap = require("dap")
	require("plugins.dap")["nvim-dap"].config()
	local source = file(
		"debug/main.c",
		'#include <stdio.h>\nint main(int argc, char **argv) {\n  printf("%s:%s\\n", argv[1], argv[2]);\n  return argc == 3 ? 0 : 1;\n}\n'
	)
	local executable = directory .. "/debug/main"
	local compile = vim.system({ "gcc", "-g", "-O0", source, "-o", executable }, { text = true })
		:wait()
	assert(compile.code == 0, compile.stderr)
	open(source, "c")
	vim.api.nvim_win_set_cursor(0, { 3, 0 })
	dap.set_breakpoint()
	local stops, ended, arguments, issue = 0, false, false, nil
	dap.listeners.after.event_stopped.config_check = function(session, body)
		stops = stops + 1
		if stops > 1 then
			dap.continue()
			return
		end
		session:request(
			"stackTrace",
			{ threadId = body.threadId, startFrame = 0, levels = 1 },
			function(err, frames)
				if err then
					issue = vim.inspect(err)
					return
				end
				session:request(
					"scopes",
					{ frameId = frames.stackFrames[1].id },
					function(scope_err, scopes)
						if scope_err then
							issue = vim.inspect(scope_err)
							return
						end
						session:request(
							"variables",
							{ variablesReference = scopes.scopes[1].variablesReference },
							function(var_err, vars)
								if var_err then
									issue = vim.inspect(var_err)
									return
								end
								for _, value in ipairs(vars.variables) do
									if value.name == "argc" and value.value == "3" then
										arguments = true
									end
								end
								dap.step_over()
							end
						)
					end
				)
			end
		)
	end
	dap.listeners.after.event_terminated.config_check = function()
		ended = true
	end
	dap.run({
		name = "Configuration check",
		type = "codelldb",
		request = "launch",
		program = executable,
		cwd = directory .. "/debug",
		args = { "hello", "two words" },
	})
	assert(
		vim.wait(30000, function()
			return ended or issue ~= nil
		end, 20),
		"DAP session timed out"
	)
	assert(ended and arguments and stops >= 2, issue or "DAP variable/step validation")
	print("PASS: compiled C program, debug variables, quoted arguments and stepping")
end

local ok, err = xpcall(check, debug.traceback)
for _, client in ipairs(vim.lsp.get_clients()) do
	client:stop(true)
end
local dap = package.loaded.dap
if dap and dap.session() then
	dap.terminate()
end
vim.wait(300)
vim.fn.delete(directory, "rf")
if not ok then
	error(err)
end
print("All integration checks passed")
