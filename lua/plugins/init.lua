local utils = require("lib.util")

---@class PlugSpec: LazyPluginSpec
---@field categories string|string[]|nil

local function trigger_user_load()
	vim.api.nvim_exec_autocmds("User", { pattern = "Load" })
	utils.nvim_loaded = true
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

---@alias EnabledPlugins boolean|table<string, EnabledPlugins>|string[]
---@alias _CategoriedPlugSpecs table<string, _CategoriedPlugSpecs>|PlugSpec[]

local switch_plugins
---switch plug
---@param enabled_list EnabledPlugins
---@param specs _CategoriedPlugSpecs
---@diagnostic disable-next-line: unused-function
switch_plugins = function(enabled_list, specs)
	if enabled_list == true then
		for _, spec_tbl in pairs(specs) do
			if spec_tbl.categories then
				spec_tbl.cond = true
			else
				switch_plugins(true, spec_tbl)
			end
		end
	elseif type(enabled_list) == "table" then
		for _, p_name in ipairs(enabled_list) do
			specs[p_name].cond = true
		end
		for cate, enabled_tbl in pairs(enabled_list) do
			switch_plugins(enabled_tbl, specs[cate])
		end
	end
end

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

--process plugin config file jsonschema
local categorized_plug = {}
local schema = {
	["$schema"] = "http://json-schema.org/draft-04/schema#",
	type = "object",
	additionalProperties = false,
	properties = {},
}
local schema_preset = {
	type = "object",
	properties = {
		enabled = {
			type = {
				"array",
				"boolean",
			},
		},
	},
}
for n, v in pairs(plugins) do
	if v.categories then
		v.cond = false
		if type(v.categories) == "string" then
			categorized_plug[v.categories] = categorized_plug[v.categories] or {}
			categorized_plug[v.categories][n] = v

			schema.properties[v.categories] = schema.properties[v.categories] or vim.fn.deepcopy(schema_preset)
			local cate_schema = schema.properties[v.categories].properties.enabled
			cate_schema.items = cate_schema.items or { enum = {} }
			cate_schema.items.enum[#cate_schema.items.enum + 1] = n
		elseif type(v.categories) == "table" then
			local final = categorized_plug
			local final_schema = schema
			---@diagnostic disable-next-line: param-type-mismatch
			for _, cate in ipairs(v.categories) do
				final[cate] = final[cate] or {}
				final = final[cate]

				final_schema.properties[cate] = final_schema.properties[cate] or vim.fn.deepcopy(schema_preset)
				final_schema = final_schema.properties[cate]
			end
			final[n] = v

			local cate_schema = final_schema.properties.enabled
			cate_schema.items = cate_schema.items or { enum = {} }
			cate_schema.items.enum[#cate_schema.items.enum + 1] = n
		end
	else
		v.cond = true
	end
end

--write json
vim.system({ "jq" }, {
	stdin = vim.fn.json_encode(schema),
}, function(res)
	if res.code == 0 then
		local file_path = vim.fn.stdpath("data") .. "/plug_schema.json"
		local file = io.open(file_path, "w")
		if file then
			file:write(res.stdout)
			file:close()
		end
	else
		vim.notify(res.stderr, vim.log.levels.ERROR)
	end
end)

switch_plugins(ENABLED_PLUGINS, categorized_plug)
return utils.table_value2array(plugins)
