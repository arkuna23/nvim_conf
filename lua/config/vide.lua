local env_get_or_default = function(key, default)
	local value = os.getenv(key)
	if value == nil then
		return default
	end
	return value
end

vim.o.guifont = env_get_or_default("CODE_FONT", "JetBrainsMono Nerd Font Mono")
	.. ":h"
	.. env_get_or_default("FONT_SIZE", "11")
vim.g.neovide_opacity = tonumber(env_get_or_default("BG_ALPHA", 0.8))
vim.g.neovide_cursor_vfx_mode = "railgun"
vim.g.transparency = tonumber(env_get_or_default("BG_ALPHA", 0.8))
vim.o.termguicolors = true
vim.cmd(string.format("highlight Normal guibg=%s", env_get_or_default("BG_COLOR", "#17456e")))
