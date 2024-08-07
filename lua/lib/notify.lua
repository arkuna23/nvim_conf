local M = {}

--- @alias progress_state integer
M.progress_state = {
	running = 0,
	success = 1,
	failed = -1,
}

--- @class ProgressNotification
--- @field spinner_idx integer spinner icon frame index
--- @field level integer log level
--- @field noti table|nil notify result
--- @field state progress_state completed
--- @field msg string message
--- @field title string title
local ProgressNotification = {}

--- @class _Sender
--- @field send fun(content: _NotifyMsg)

--- @class _Receiver
--- @field recv fun(): _NotifyMsg

--- @class _NotifyMsg
--- @field stop boolean|nil stop notify loop, will ignore other fields and stop
--- @field msg string|nil message
--- @field opts table|nil vim.notify opts
--- @field reuse boolean|nil whether reuse this notification
--- @field inherit boolean|nil reuse last notification with reuse flag, same as opts.replace
--- @field level integer|nil log level

local spinner_frames = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" }
--- create progress notification and send
--- @param title string
--- @param msg string
--- @param level integer|nil
--- @return ProgressNotification
function ProgressNotification:create(title, msg, level)
	local o = {
		spinner_idx = 1,
		level = level,
		state = M.progress_state.running,
		title = title,
		msg = msg,
	}
	setmetatable(o, { __index = self })

	level = level or vim.log.levels.INFO
	o.noti = vim.notify(msg, level, {
		title = title,
		timeout = false,
		icon = spinner_frames[o.spinner_idx],
	})
	o:_start_update_loop()
	return o
end

function ProgressNotification:_start_update_loop()
	local async = require("plenary.async")

	local update_loop
	update_loop = function()
		local send_fn = function(icon, last)
			local opts = {
				title = self.title,
				icon = icon,
				replace = self.noti,
				hide_from_history = not last,
				timeout = last and 2000 or nil,
			}
			if last then
				vim.notify(self.msg, self.level, opts)
			else
				self.noti = vim.notify(self.msg, self.level, opts)
			end
		end

		while self.state == M.progress_state.running do
			self.spinner_idx = (self.spinner_idx % #spinner_frames) + 1
			send_fn(spinner_frames[self.spinner_idx], false)
			async.util.sleep(100)
		end
		if self.state == M.progress_state.failed then
			send_fn("󰅙", true)
		elseif self.state == M.progress_state.success then
			send_fn("", true)
		end
	end

	---@diagnostic disable: missing-parameter
	async.run(update_loop)
	---@diagnostic enable: missing-parameter
end

--- update notification message
--- @param msg string
function ProgressNotification:update(msg)
	assert(self.state == M.progress_state.running, "already completed")
	self.msg = msg
end

--- progress completed
--- @param msg string
--- @param is_failed boolean|nil
function ProgressNotification:complete(msg, is_failed)
	assert(self.state == M.progress_state.running, "already completed")
	if is_failed then
		vim.notify(msg, vim.log.levels.ERROR, {
			title = self.title,
			icon = "󰅙",
		})
		self.state = M.progress_state.failed
	else
		self.msg = msg
		self.state = M.progress_state.success
	end
end

M.ProgressNotification = ProgressNotification

return M
