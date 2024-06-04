local M = {}

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
			tbl[k] = tbl[k] or v
		end
	else
		tbl = default_tbl
	end
	return tbl
end

return M
