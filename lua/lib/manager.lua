local M = {}

local flag_path = vim.fn.stdpath("state") .. "/enable_plug.flag"

M.load_lazy = function()
	-- clone lazy.nvim
	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

	---@diagnostic disable-next-line: undefined-field
	if not vim.uv.fs_stat(lazypath) then
		-- bootstrap lazy.nvim
		vim.fn.system({
			"git",
			"clone",
			"--filter=blob:none",
			"https://github.com/folke/lazy.nvim.git",
			"--branch=stable",
			lazypath,
		})
	end
	vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

	require("lazy").setup(require("plugins.init"), {
		performance = {
			rtp = {
				disabled_plugins = {
					"editorconfig",
					"gzip",
					"matchit",
					"matchparen",
					"netrwPlugin",
					"shada",
					"tarPlugin",
					"tohtml",
					"tutor",
					"zipPlugin",
				},
			},
		},
		ui = {
			backdrop = 60,
		},
	})
	require("config.init").setup()
end

M.plugin_enabled = function()
	---@diagnostic disable-next-line: undefined-field
	return vim.uv.fs_stat(flag_path)
end

M.toggle_plugin_enabled = function()
	if M.plugin_enabled() then
		local succ, err = os.remove(flag_path)
		if succ then
			vim.notify("Plugins disabled, will be effective at the next start")
		elseif err then
			vim.notify(err, vim.log.levels.ERROR)
		end
	else
		local f, err = io.open(flag_path, "w")
		if f then
			f:write("enabled")
			f:close()
			vim.notify("Plugins enabled, please restart your neovim")
			M.load_lazy()
		elseif err then
			vim.notify(err, vim.log.levels.ERROR)
		end
	end
end

return M
