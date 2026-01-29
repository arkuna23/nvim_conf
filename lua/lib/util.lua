local M = {}
---@alias optvalue function|nil

---convert table elements to array
---@param table table
---@return table
M.table_value2array = function(table)
	local array = {}
	for _, v in pairs(table) do
		array[#array + 1] = v
	end
	return array
end

---read file content into lines
---@param path string
---@return table | nil
M.read_file_lines = function(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	local lines = {}
	for line in file:lines() do
		lines[#lines + 1] = line
	end
	file:close()
	return lines
end

---read whole file
---@param path string
---@return string|nil
M.read_file = function(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	return file:read("*a")
end

M.config_root = function()
	return vim.fn.stdpath("config")
end

M.delegate_call = function(mod_name, fn_name, ...)
	local args = { ... }
	return function()
		require(mod_name)[fn_name](table.unpack(args))
	end
end

--- trim ending whitespace
--- @param inputString string
--- @return string
string.trim_end = function(inputString)
	---@diagnostic disable-next-line: undefined-field
	local result, _ = inputString:gsub("[ \r\n]*$", "")
	return result
end

os.file_exists = function(file)
	local fid = io.open(file, "r")
	if fid ~= nil then
		io.close(fid)
		return true
	else
		return false
	end
end

os.get_os_release = function()
	local file =
		io.popen("cat /etc/*-release | grep '^PRETTY_NAME=' | awk -F'=' '{print $2}' | tr -d '\"'")
	assert(file, "invalid os")
	local distro = string.trim_end(file:read("*a"))
	file:close()
	os.get_os_release = function()
		return distro
	end
	return distro
end

os.get_username = function()
	local user = os.getenv("USER")
	os.get_username = function()
		return user
	end
	return os.get_username()
end

M.get_startup_stats = function()
	if not M._startupStats then
		local stats = require("lazy").stats()
		M._startupStats = {
			timeMs = math.floor(stats.startuptime * 100 + 0.5) / 100,
			loaded = stats.loaded,
			total = stats.count,
		}
	end

	return M._startupStats
end

M.is_buffer_alive = function(bufname)
	local buffers = vim.api.nvim_list_bufs()
	for _, buf in ipairs(buffers) do
		if vim.api.nvim_buf_get_name(buf) == bufname then
			return true
		end
	end
	return false
end

---parse dynamic value
---@param dyn_value any
---@return any
M.parse_dyn_value = function(dyn_value)
	return type(dyn_value) == "function" and dyn_value() or dyn_value
end

---transform table with dynamic values
---@param dyn_table table
---@param exclude string[]|nil
M.process_dyn_table = function(dyn_table, exclude)
	exclude = M.list2hashtable(exclude or {})
	for k, v in pairs(dyn_table) do
		if (not exclude[k]) and type(v) == "function" then
			dyn_table[k] = v()
		end
	end
end

---convert list items to table keys
---@param list any[]
---@return table
M.list2hashtable = function(list)
	local hash = {}
	for _, v in ipairs(list) do
		hash[v] = true
	end
	return hash
end

M.log_warn = function(msg)
	vim.notify(msg, vim.log.levels.WARN)
end

---get mason installed package path
---@param pkg string
---@param path string
---@param opts table|nil
---@return string location
M.get_pkg_path = function(pkg, path, opts)
	pcall(require, "mason") -- make sure Mason is loaded. Will fail when generating docs
	local root = vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")
	opts = opts or {}
	opts.warn = opts.warn == nil and true or opts.warn
	path = path or ""
	local ret = root .. "/packages/" .. pkg .. "/" .. path
	if opts.warn and not vim.loop.fs_stat(ret) then
		---@diagnostic disable-next-line: undefined-field
		M.log_warn(("Mason package path not found for **%s**:\n- `%s`"):format(pkg, path))
	end
	return ret
end

---get table keys
---@param t table
---@return table
table.keys = function(t)
	local keys = {}
	for k, _ in pairs(t) do
		if string.sub(k, 1, 1) ~= "_" then
			table.insert(keys, k)
		end
	end
	--vim.defer_fn(function()
	--	vim.notify(table.concat(keys, ", "))
	--end, 1000)

	return keys
end

---check whether list contains specified element
---@param list table
---@param ele any
---@return boolean
table.list_contains = function(list, ele)
	for _, e in ipairs(list) do
		if e == ele then
			return true
		end
	end

	return false
end

---set table default values
---@param tbl table|nil
---@param default_tbl table
table.default_values = function(tbl, default_tbl)
	if tbl then
		for k, v in pairs(default_tbl) do
			if tbl[k] == nil then
				tbl[k] = v
			end
		end
	else
		tbl = default_tbl
	end
	return tbl
end

table.deep_copy = function(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == "table" then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[table.deep_copy(orig_key)] = table.deep_copy(orig_value)
		end
		setmetatable(copy, table.deep_copy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

---get layout, depend on window size
---@return 'horizontal' | 'vertical'
M.get_proper_layout = function()
	return (
		vim.api.nvim_get_option_value("columns", {
			scope = "global",
		}) > vim.api.nvim_get_option_value("lines", {
			scope = "global",
		}) * 2.5
	)
			and "horizontal"
		or "vertical"
end

---convert array to hash table
---@param array any[]|nil
---@return table|nil
M.array_to_hash = function(array)
	if not array then
		return nil
	end

	local hash = {}
	for _, v in ipairs(array) do
		hash[v] = true
	end
	return hash
end

M.is_docker = function()
	return vim.fn.empty(vim.fn.glob("/.dockerenv")) == 0
end

return M
