local mason_lspconfig = require("mason-lspconfig.mappings")
local conf = require("plugins.conf")

local map = mason_lspconfig.get_mason_map()

print("Installing mason packages...")

local function install(name)
	local succ, res = pcall(vim.api.nvim_command, "MasonInstall " .. name)
	if not succ then
		print("Error: " .. res)
	end
end

for key, _ in pairs(conf.lsp()) do
	print("Install: " .. key)
	install(map.lspconfig_to_package[key])
end

for _, name in ipairs(conf.mason.packages()) do
	print("Install: " .. name)
	install(name)
end
