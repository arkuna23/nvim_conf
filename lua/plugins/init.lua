local manager = require("lib.manager")
local util = require("lib.util")

---@class PlugSpec: LazyPluginSpec
---@field categories string|string[]|nil

local function trigger_user_load()
	vim.api.nvim_exec_autocmds("User", { pattern = "Load" })
	util.nvim_loaded = true
end

-- User Load: triggered when editing a file
vim.api.nvim_create_autocmd("User", {
	pattern = "VeryLazy",
	callback = function()
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

-- lazy load theme
vim.api.nvim_create_autocmd("User", {
	pattern = "VeryLazy",
	callback = function()
		require(COLORSCHEME)
		vim.cmd("colorscheme " .. COLORSCHEME)
        if vim.g.neovide then
            require('config.vide').setup()
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
local categorized_plug, schema = manager.catogrize_plugins(plugins)

--write jsonschema
vim.system({ "jq" }, {
	stdin = vim.fn.json_encode(schema),
}, function(res)
	if res.code == 0 then
		local file = io.open(vim.fn.stdpath("data") .. "/plug_schema.json", "w")
		if file then
			file:write(res.stdout)
			file:close()
		end
	else
		vim.notify(res.stderr, vim.log.levels.ERROR)
	end
end)

--read plugin jsonconf
local file_content =
	vim.fn.json_decode(vim.fn.readfile(vim.fn.stdpath("config") .. "/conf/plugins_loaded.json"))
manager.switch_plugins(manager.process_plug_jsonconf(file_content), categorized_plug)
return util.table_value2array(plugins)
