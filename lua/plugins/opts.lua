local M = {}
local plug_opts = {}

plug_opts["clangd_extensions"] = function()
	local symbols = require("lib.symbols")
	return {
		inlay_hints = {
			inline = false,
		},
		ast = {
			--These require codicons (https://github.com/microsoft/vscode-codicons)
			role_icons = {
				type = symbols.Type,
				declaration = symbols.Declaration,
				expression = symbols.Circle,
				specifier = symbols.ListTree,
				statement = symbols.SymbolEvent,
				["template argument"] = symbols.Template,
			},
			kind_icons = {
				Compound = symbols.Namespace,
				Recovery = symbols.Error,
				TranslationUnit = symbols.CodeFile,
				PackExpansion = symbols.Ellipsis,
				TemplateTypeParm = symbols.Template,
				TemplateTemplateParm = symbols.Template,
				TemplateParamObject = symbols.Template,
			},
		},
	}
end

---get plugin opts loader func by name
---@param name string
---@return fun(): table
M.get_plug_opts = function(name)
	return function()
		if type(plug_opts[name]) == "function" then
			plug_opts[name] = plug_opts[name]()
		end
		return plug_opts[name]
	end
end

return M
