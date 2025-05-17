---lazy load module
---@param modname string
---@diagnostic disable-next-line: lowercase-global
function lazy_require(modname)
	local module
	return setmetatable({}, {
		__index = function(_, field)
			return function(...)
				if not module then
					module = require(modname)
				end
				return module[field](...)
			end
		end,
	})
end

require("lazy_init")
