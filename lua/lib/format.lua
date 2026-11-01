local M = {}

function M.web_formatters(bufnr)
	local file = vim.api.nvim_buf_get_name(bufnr)
	local root = vim.fs.find({ "biome.json", "biome.jsonc", ".biome.json", ".biome.jsonc" }, {
		path = vim.fs.dirname(file),
		upward = true,
		type = "file",
	})[1]
	if root and require("conform").get_formatter_info("biome", bufnr).available then
		return { "biome" }
	end
	return { "prettier" }
end

function M.prettier_args(self, ctx)
	local command = self.command
	if type(command) == "function" then
		command = command(self, ctx)
	end
	local result = vim.system({ command, "--find-config-path", ctx.filename }, {
		cwd = ctx.dirname,
		text = true,
	}):wait(1000)
	if result.code == 1 then
		return { "--config", vim.fn.stdpath("config") .. "/conf/.prettierrc.json" }
	end
	return {}
end

return M
