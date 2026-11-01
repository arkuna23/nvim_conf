local M = {}

local aliases = {
	["js/ts"] = "js",
	javascript = "js",
	typescript = "js",
	c = "c/cpp",
	cpp = "c/cpp",
	["c++"] = "c/cpp",
	csharp = "c#",
	tailwind = "tailwindcss",
}

function M.normalize(lang)
	return aliases[lang] or lang
end

function M.enabled(lang)
	if type(lang) == "table" then
		for _, value in ipairs(lang) do
			if M.enabled(value) then
				return true
			end
		end
		return false
	end
	local selected = require("lib.user_config").editor_lang
	if not selected or not lang then
		return true
	end
	for _, value in ipairs(selected) do
		if M.normalize(value) == M.normalize(lang) then
			return true
		end
	end
	return false
end

return M
