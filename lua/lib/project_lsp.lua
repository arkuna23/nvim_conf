local M = {}

local function project_settings(name, file)
	local workspace = require("neoconf.workspace").get({ file = file })
	return workspace.settings:get("lspconfig." .. name), workspace
end

function M.enabled(name, bufnr)
	local file = vim.api.nvim_buf_get_name(bufnr)
	local settings, workspace = project_settings(name, file)
	return settings ~= false and workspace.settings:get(name .. ".disable") ~= true
end

function M.settings(name, file, defaults)
	local Settings = require("neoconf.settings")
	local global = Settings.get_global()
	local _, workspace = project_settings(name, file)
	local local_settings = Settings.get_local(workspace.root_dir)
	local result = vim.deepcopy(defaults or {})
	local imports = require("neoconf.config").get({ file = file }).import
	for _, source in ipairs({ global, local_settings }) do
		for _, kind in ipairs({ "vscode", "coc", "nlsp" }) do
			if imports[kind] then
				local key = kind == "nlsp" and "nlsp." .. name or kind
				result =
					vim.tbl_deep_extend("force", result, source:get(key, { expand = true }) or {})
			end
		end
	end
	for _, source in ipairs({ global, local_settings }) do
		local settings = source:get("lspconfig." .. name, { expand = true })
		if type(settings) == "table" then
			result = vim.tbl_deep_extend("force", result, settings)
		end
	end
	return result
end

function M.wrap(name, config)
	local root_dir = config.root_dir
	local before_init = config.before_init
	return {
		root_dir = function(bufnr, on_dir)
			if not M.enabled(name, bufnr) then
				return
			end
			if type(root_dir) == "function" then
				root_dir(bufnr, on_dir)
			else
				local root = root_dir
				for _, markers in ipairs(config.root_markers or {}) do
					root = root
						or vim.fs.root(bufnr, type(markers) == "table" and markers or { markers })
					if root then
						break
					end
				end
				on_dir(root)
			end
		end,
		before_init = function(params, client_config)
			if before_init then
				before_init(params, client_config)
			end
			client_config.settings =
				M.settings(name, client_config.root_dir, client_config.settings)
		end,
	}
end

return M
