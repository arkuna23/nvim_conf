local root =
	vim.fs.dirname(vim.fs.dirname(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")))
vim.opt.rtp:prepend(root)
for _, name in ipairs({ "mason.nvim", "mason-lspconfig.nvim", "nvim-lspconfig" }) do
	vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/" .. name)
end
require("mason").setup()

local registry = require("mason-registry")
local refreshed, available = false, false
registry.refresh(function(success)
	available, refreshed = success, true
end)
assert(
	vim.wait(60000, function()
		return refreshed
	end),
	"Mason registry refresh timed out"
)
assert(available, "Mason registry refresh failed; see :MasonLog")

local packages = {}
for _, name in ipairs(arg or {}) do
	packages[name] = true
end
if next(packages) == nil then
	local conf = require("plugins.conf")
	local mapping = require("mason-lspconfig.mappings").get_mason_map().lspconfig_to_package
	for name in pairs(conf.lsp()) do
		packages[assert(mapping[name], name)] = true
	end
	for _, name in ipairs(conf.mason.packages()) do
		packages[name] = true
	end
	local languages = require("lib.languages")
	if languages.enabled({ "c/cpp", "rust" }) then
		packages.codelldb = true
	end
	if languages.enabled("kotlin") then
		packages["kotlin-debug-adapter"] = true
	end
end

local pending, failures = 0, {}
for _, name in ipairs(vim.fn.sort(vim.tbl_keys(packages))) do
	local pkg = registry.get_package(name)
	if pkg:is_installed() then
		print("Installed: " .. name)
	else
		pending = pending + 1
		pkg:install({}, function(success, err)
			pending = pending - 1
			if success then
				print("Installed: " .. name)
			else
				failures[#failures + 1] = name .. ": " .. tostring(err)
			end
		end)
	end
end
assert(
	vim.wait(900000, function()
		return pending == 0
	end),
	"Mason installation timed out; see :MasonLog"
)
assert(#failures == 0, table.concat(failures, "\n"))
print("Mason tools ready")
