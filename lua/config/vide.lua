local M = {}

local env_get_or_default = function(key, default)
	local value = os.getenv(key)
	if value == nil then
		return default
	end
	return value
end

M.setup = function()
	vim.o.guifont = env_get_or_default("CODE_FONT", "JetBrainsMono Nerd Font Mono") .. ":h13"
	vim.g.neovide_transparency = tonumber(env_get_or_default("BG_ALPHA1", 0.8))
	vim.g.transparency = tonumber(env_get_or_default("BG_ALPHA1", 0.8))
	vim.g.neovide_cursor_vfx_mode = "wireframe"
	vim.o.termguicolors = true
	vim.cmd(string.format("highlight Normal guibg=%s", env_get_or_default("BG_COLOR", "#17456e")))
end

return M
