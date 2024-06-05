local M = {}
---@alias optvalue function|nil

---convert table elements to array
---@param table table
---@return table
M.table2array = function(table)
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

M.config_root = vim.fn.stdpath("config")

M.nvim_loaded = false

M.delegate_call = function(name, fn_name, ...)
	local args = { ... }
	return function()
		require(name)[fn_name](table.unpack(args))
	end
end

local PDFViewer = {
	pdf_preview_port = 8999,
}

---start pdf preview server
---@param filename string
function PDFViewer:run(filename)
	if self.server then
		self:stop()
	end

	local cmd = M.config_root .. "/etc/pdf-preview/" .. string.lower(jit.os) .. "-" .. jit.arch
	local server = vim.fn.jobstart({ cmd, filename, self.pdf_preview_port }, {
		cwd = vim.fn.getcwd(),
		on_exit = function(_, return_val)
			if return_val ~= 0 then
				vim.notify("pdf live preview exited with code " .. return_val)
			end
		end,
	})
	self.filename = filename
	self.server = server
end

---open browser to preview, bind a buffer
---@param filename string
---@param bufname string stop server on buf close
function PDFViewer:open(filename, bufname)
	-- has not started or change file
	if filename ~= self.filename then
		self:run(filename)
		self._buffer = bufname

		-- if current server has not been binded to a buffer, bind it to the current buffer
		if not self._init then
			vim.api.nvim_create_autocmd("BufDelete", {
				callback = function()
					if vim.api.nvim_buf_get_name(0) then
						self._buffer = nil
						self:stop()
					end
				end,
			})
			self._init = true
		end
	end

	if self.server then
		vim.fn.jobstart({ "xdg-open", "http://127.0.0.1:" .. self.pdf_preview_port })
	end
end

---stop pdf viewer server
function PDFViewer:stop()
	vim.system({ "curl", "-X", "POST", "http://127.0.0.1:" .. self.pdf_preview_port .. "/stop" }):wait()
	self.server = nil
end

M.PDFViewer = PDFViewer

---split string by delimiter
---@param inputString string
---@param delimiter string
---@return table
string.split = function(inputString, delimiter)
	local result = {}
	local pattern = "(.-)" .. delimiter .. "()"
	local currentPosition = 1
	for part, _ in string.gmatch(inputString, pattern) do
		result[currentPosition] = part
		currentPosition = currentPosition + 1
	end
	return result
end

---pad string to specified length
---@param inputString string
---@param length number
---@param padding string
---@return string | nil
string.pad_string = function(inputString, length, padding)
	if #padding ~= 1 then
		return nil
	end

	local strLength = #inputString
	if strLength >= length then
		return inputString
	else
		local spaces = length - strLength
		return inputString .. string.rep(padding, spaces)
	end
end

--- trim ending whitespace
--- @param inputString string
--- @return string
string.trim_end = function(inputString)
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
	local file = io.popen("cat /etc/*-release | grep '^PRETTY_NAME=' | awk -F'=' '{print $2}' | tr -d '\"'")
	local distro = string.trim_end(file:read("*a"))
	file:close()
	os.get_os_release = function()
		return distro
	end
	return distro
end

os.get_username = function()
	return os.getenv("USER")
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

return M
