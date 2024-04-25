local env = function(name)
	return os.getenv(name)
end

vim.o.guifont = env("CODE_FONT") .. ":h13"
vim.g.neovide_transparency = tonumber(env("BG_ALPHA"))
vim.g.transparency = tonumber(env("BG_ALPHA"))
vim.g.neovide_cursor_vfx_mode = "wireframe"
vim.o.termguicolors = true
vim.cmd(string.format("highlight Normal guibg=%s", env("BG_COLOR")))
