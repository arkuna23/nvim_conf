local M = {}

local flag_path = vim.fn.stdpath("state") .. "/enable_plug.flag"

M.load_lazy = function()
	-- clone lazy.nvim
	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

	---@diagnostic disable-next-line: undefined-field
	if not vim.uv.fs_stat(lazypath) then
		-- bootstrap lazy.nvim
		vim.fn.system({
			"git",
			"clone",
			"--filter=blob:none",
			"https://github.com/folke/lazy.nvim.git",
			"--branch=stable",
			lazypath,
		})
	end
	vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

	require("lazy").setup(require("plugins.init"), {
		performance = {
			rtp = {
				disabled_plugins = {
					"editorconfig",
					"gzip",
					"matchit",
					"matchparen",
					"netrwPlugin",
					"shada",
					"tarPlugin",
					"tohtml",
					"tutor",
					"zipPlugin",
				},
			},
		},
		ui = {
			backdrop = 60,
		},
	})
end

M.plugins_enabled = function()
	---@diagnostic disable-next-line: undefined-field
	local state = vim.uv.fs_stat(flag_path)
	M.plugins_enabled = function()
		return state
	end
	return M.plugins_enabled()
end

M.toggle_plugins_enabled = function()
	if M.plugins_enabled() then
		local succ, err = os.remove(flag_path)
		if succ then
			vim.notify("Plugins disabled, will be effective at the next start")
		elseif err then
			vim.notify(err, vim.log.levels.ERROR)
		end
	else
		local f, err = io.open(flag_path, "w")
		if f then
			f:write("enabled")
			f:close()
			vim.notify("Plugins enabled, please restart your neovim")
			M.load_lazy()
		elseif err then
			vim.notify(err, vim.log.levels.ERROR)
		end
	end
end

---@alias EnabledPlugins boolean|table<string, EnabledPlugins>|string[]
---@alias _CategoriedPlugSpecs table<string, _CategoriedPlugSpecs>|PlugSpec[]
---switch plug
---@param enabled_list EnabledPlugins
---@param specs _CategoriedPlugSpecs
---@diagnostic disable-next-line: unused-function
M.switch_plugin = function(enabled_list, specs)
	if enabled_list == true then
		for _, spec_tbl in pairs(specs) do
			if spec_tbl.categories then
				spec_tbl.cond = true
			else
				M.switch_plugin(true, spec_tbl)
			end
		end
	elseif type(enabled_list) == "table" then
		for _, p_name in ipairs(enabled_list) do
			specs[p_name].cond = true
		end
		for cate, enabled_tbl in pairs(enabled_list) do
			---@diagnostic disable-next-line: param-type-mismatch
			M.switch_plugin(enabled_tbl, specs[cate])
		end
	end
end

local specs = nil

M.plugin_specs_loaded = function()
	return specs ~= nil
end

---get plugin spec by name
---@param name string
---@return PlugSpec|nil
M.get_plug_spec = function(name)
	return specs and specs[name] or nil
end

---set plugin specs
---@param plug_specs table
M.set_plugin_specs = function(plug_specs)
	specs = plug_specs
end

local categorized

M.set_categorized_plugins = function(plug_specs)
	categorized = plug_specs
end

---categorize plugins, make json-schema and cache specs
---@param plugin_specs table<string, PlugSpec>
---@return table "categorized plugin table"
---@return table "json-schema table"
M.catogrize_plugins = function(plugin_specs)
	local categorized_plug = {}
	local schema = {
		["$schema"] = "http://json-schema.org/draft-04/schema#",
		type = "object",
		additionalProperties = false,
		properties = {
			["enable-all"] = {
				type = "boolean",
			},
		},
	}
	local schema_preset = {
		type = {
			"object",
			"boolean",
		},
		properties = {
			enabled = {
				type = "array",
			},
		},
	}

	for n, v in pairs(plugin_specs) do
		if v.categories then
			v.cond = false
			if type(v.categories) == "string" then
				categorized_plug[v.categories] = categorized_plug[v.categories] or {}
				categorized_plug[v.categories][n] = v

				schema.properties[v.categories] = schema.properties[v.categories]
					or vim.fn.deepcopy(schema_preset)
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

					final_schema.properties[cate] = final_schema.properties[cate]
						or vim.fn.deepcopy(schema_preset)
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

	return categorized_plug, schema
end

---transform plugins_loaded.json into value which can be processed
---@param json table
---@return boolean|table
M.process_plug_jsonconf = function(json)
	local result
	if json["enable-all"] then
		result = true
	else
		json["enable-all"] = nil
		result = {}

		---@diagnostic disable-next-line: unused-function
		local function process_sub(sub_ele)
			local sub_res
			if type(sub_ele) == "boolean" then
				sub_res = sub_ele
			else
				sub_res = {}
				for _, plug in ipairs(sub_ele.enabled or {}) do
					sub_res[#sub_res + 1] = plug
				end
				sub_ele.enabled = nil
				for k, value in pairs(sub_ele) do
					sub_res[k] = process_sub(value)
				end
			end
			return sub_res
		end

		for key, value in pairs(json) do
			result[key] = process_sub(value)
		end
	end

	return result
end

return M
