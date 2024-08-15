---@diagnostic disable-next-line: unused-local
local server_version = "v0.1.0"
local server_dir = vim.fn.stdpath("data") .. "/pdf-prev-server"
local server_path = server_dir .. "/pdf-preview-server"

local PDFViewer = {
	pdf_preview_port = 8999,
}

---start pdf preview server
---@param filename string
function PDFViewer:run(filename)
	if self.server then
		self:stop()
	end

	local server = vim.fn.jobstart({ server_path, filename, self.pdf_preview_port }, {
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

		-- if current server has not been binded to a buffer, bind it to current buffer
		if not self._init then
			vim.api.nvim_create_autocmd("BufDelete", {
				callback = function()
					if vim.api.nvim_buf_get_name(0) == self._buffer then
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
	vim.system({ "curl", "-X", "POST", "http://127.0.0.1:" .. self.pdf_preview_port .. "/stop" })
		:wait()
	self.server = nil
end

local buffers = {}

local server_setup = function()
	local async = require("plenary.async")
	local notify = require("lib.notify")
	local async_lib = require("lib.async")

	-- download
	local download = function(pack_name, succ_fn)
		local noti = notify.ProgressNotification:create(
			"Download Server",
			"Downloading pdf preview server..."
		)

		if not vim.uv.fs_stat(server_dir .. "/" .. pack_name) then
			local out = async_lib.system({
				"wget",
				"-P",
				server_dir,
				"https://github.com/arkuna23/pdf-preview-server/releases/download/"
					.. server_version
					.. "/"
					.. pack_name,
			}, { text = true })

			if out.code ~= 0 then
				noti:complete(out.stderr, true)
				return
			end
		end

		local succ, err = pcall(succ_fn, noti)
		if succ then
			noti:complete("Downloaded and extracted successfully.")
			os.remove(server_dir .. "/" .. pack_name)
		else
			noti:complete(err, true)
		end
	end

	if not vim.uv.fs_stat(server_path) then
		local sysname = vim.uv.os_uname().sysname
		local extract_msg = "Extracting server file..."

		-- download and extract
		---@diagnostic disable-next-line: missing-parameter
		async.run(function()
			if sysname == "Linux" then
				local pack_name = "pdf-preview-server-x86_64-unknown-linux-gnu.tar.gz"
				download(pack_name, function(noti)
					noti:update(extract_msg)
					local res = async_lib.system({
						"tar",
						"-C",
						server_dir,
						"-zxvf",
						server_dir .. "/" .. pack_name,
					})
					assert(res.code == 0, res.stderr)
				end)
			end
		end)
	end
end

return {
	PDFViewer = PDFViewer,
	latex_preview = function()
		local bufname = vim.api.nvim_buf_get_name(0)
		if not buffers[bufname] then
			vim.cmd("VimtexCompile")
			buffers[bufname] = true
		end
		PDFViewer:open(bufname:gsub("%.%w+$", ".pdf"), bufname)
	end,
	server_setup = server_setup,
}
