local manager = require("lib.manager")
local util = require("lib.util")

---@class PlugSpec: LazyPluginSpec
---@field categories string|string[]|nil

local function trigger_user_load()
	vim.api.nvim_exec_autocmds("User", { pattern = "Load" })
end

local function load_ui()
	require(COLORSCHEME)
	vim.cmd("colorscheme " .. COLORSCHEME)
	if vim.g.neovide then
		require("config.vide")
	end
end

-- User Load: triggered when editing a file
vim.api.nvim_create_autocmd("User", {
	pattern = "VeryLazy",
	callback = function()
		load_ui()
		if vim.bo.filetype == "dashboard" then
			vim.api.nvim_create_autocmd("BufRead", {
				once = true,
				callback = trigger_user_load,
			})
		else
			trigger_user_load()
		end
	end,
})

---@diagnostic disable-next-line: unused-function

--load plugins config
---@type table<string, PlugSpec>
local plugins = vim.tbl_extend(
	"keep",
	require("plugins.ui"),
	require("plugins.lsp"),
	require("plugins.lang"),
	require("plugins.colorschemes"),
	require("plugins.editor"),
	require("plugins.dap"),
	require("plugins.etc")
)
manager.set_plugin_specs(plugins)
local categorized_plug, schema = manager.catogrize_plugins(plugins)
manager.set_categorized_plugins(categorized_plug)

local function write_plugin_schema()
	local path = vim.fn.stdpath("data") .. "/plug_schema.json"
	util.write_file(path, vim.json.encode(schema))
end

local function read_plugin_config()
	local default = { ["enable-all"] = true }
	return util.read_json_file(
		vim.fn.stdpath("config") .. "/conf/plugins_loaded.json",
		default,
		{ notify_name = "conf/plugins_loaded.json" }
	)
end

write_plugin_schema()
manager.switch_plugin(manager.process_plug_jsonconf(read_plugin_config()), categorized_plug)
return util.table_value2array(plugins)
