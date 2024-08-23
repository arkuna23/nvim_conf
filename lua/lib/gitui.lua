local M = {}

---@class GiTui
---@field term Terminal
local GiTui = {}

function GiTui:new()
	self.__index = self
	local o = {}
	setmetatable(o, self)
	o.term = require("toggleterm.terminal").Terminal:new({
		cmd = "gitui",
		hidden = true,
	})
	return o
end

function GiTui:toggle()
	self.term:toggle()
end

M.GiTui = GiTui
---@type GiTui|nil
local gitui = nil

M.toggle = function()
	gitui = gitui or GiTui:new()
	gitui:toggle()
end

return M
