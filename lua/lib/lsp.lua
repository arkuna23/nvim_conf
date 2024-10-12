local lsp = {}

local lsp_default_flags = {
	debounce_text_changes = 150,
}

local lsp_default_keybindings = {
	["lsp_info"] = { "<leader>cl", "<cmd>LspInfo<CR>", "n", "Lsp Info" }, -- Lsp Info
	["definitions"] = { "gd", "<cmd>Telescope lsp_definitions<CR>", "n", "Goto Definitions" }, -- Goto Definition
	["references"] = { "gr", "<cmd>Telescope lsp_references<CR>", "n", "References" }, -- References
	["declaration"] = { "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", "n", "Goto Declaration" }, -- Goto Declaration
	["type_implementations"] = {
		"gI",
		"<cmd>Telescope lsp_implementations<CR>",
		"n",
		"Goto Implementations",
	}, -- Goto Implementation
	["type_definitions"] = {
		"gy",
		"<cmd>Telescope lsp_type_definitions<CR>",
		"n",
		"Goto Type Definitions",
	}, -- Goto Type Definition
	["hover"] = { "T", "<cmd>lua vim.lsp.buf.hover()<CR>", "n", "Hover" }, -- Hover
	["signature_help"] = {
		"gK",
		"<cmd>lua vim.lsp.buf.signature_help()<CR>",
		"n",
		"Signature Help",
	}, -- Signature Help
	["signature_help_insert"] = {
		"<c-k>",
		"<cmd>lua vim.lsp.buf.signature_help()<CR>",
		"i",
		"Signature Help (Insert mode)",
	}, -- Signature Help (Insert mode)
	["code_action"] = {
		"<leader>ca",
		"<cmd>lua vim.lsp.buf.code_action()<CR>",
		"n,v",
		"Code Action",
	}, -- Code Action
	["run_codelens"] = {
		"<leader>cc",
		"<cmd>lua vim.lsp.codelens.run()<CR>",
		"n,v",
		"Run Codelens",
	}, -- Run Codelens
	["refresh_codelens"] = {
		"<leader>cC",
		"<cmd>lua vim.lsp.codelens.refresh()<CR>",
		"n",
		"Refresh & Display Codelens",
	}, -- Refresh & Display Codelens
	["source_action"] = {
		"<leader>cA",
		"<cmd>lua vim.lsp.buf.source_action()<CR>",
		"n",
		"Source Action",
	}, -- Source Action
	["rename"] = { "<leader>cr", "<cmd>lua vim.lsp.buf.rename()<CR>", "n", "Rename" }, -- Rename
	["document_diagnostic"] = {
		"<leader>xx",
		"<cmd>Trouble diagnostics toggle filter.buf=0<CR>",
		"n",
		"Document Diagnostics",
	}, -- Document Diagnostics
	["workspace_diagnostic"] = {
		"<leader>xX",
		"<cmd>Trouble diagnostics toggle<CR>",
		"n",
		"Workspace Diagnostics",
	}, -- Workspace Diagnostics
	["extract_function"] = {
		"<leader>re",
		function()
			require("refactoring").refactor("Extract Function")
		end,
		"x",
		"Extract Function",
	}, -- Extract function supports only visual mode
	["extract_function_file"] = {
		"<leader>rf",
		function()
			require("refactoring").refactor("Extract Function To File")
		end,
		"x",
		"Extract Function To File",
	}, -- Extract variable supports only visual mode
	["extract_var"] = {
		"<leader>rv",
		function()
			require("refactoring").refactor("Extract Variable")
		end,
		"n",
		"Extract Variable",
	},
	["inline_func"] = {
		"<leader>rI",
		function()
			require("refactoring").refactor("Inline Function")
		end,
		"n",
		"Inline Function",
	}, -- Inline func supports only normal
	["inline_var"] = {
		"<leader>ri",
		function()
			require("refactoring").refactor("Inline Variable")
		end,
		"n,x",
		"Inline Variable",
	}, -- Inline var supports both normal and visual mode,
	["extract_block"] = {
		"<leader>rb",
		function()
			require("refactoring").refactor("Extract Block")
		end,
		"n",
		"Extract Block",
	},
	["extract_block_file"] = {
		"<leader>rbf",
		function()
			require("refactoring").refactor("Extract Block To File")
		end,
	}, -- Extract block supports only normal mode
}
local lsp_default_on_attach = function(client, _)
	client.server_capabilities.documentFormattingProvider = false
	client.server_capabilities.documentRangeFormattingProvider = false

	-- copilot
	if client.name == "copilot" then
		require("copilot_cmp")._on_insert_enter({})
	end
end

local lsp_default_config = function()
	return {
		capabilities = require("cmp_nvim_lsp").default_capabilities(),
		flags = lsp_default_flags,
		-- default attach actions
	}
end

lsp.merge_keybindings = function(old, new)
	return vim.tbl_extend("force", old, new)
end

---attach keys on specified buffer
---@param buffer any
---@param keybindings table|nil
lsp.key_attach = function(buffer, keybindings)
	keybindings = keybindings or lsp_default_keybindings
	for _, binding in pairs(keybindings) do
		local modes = vim.split(binding[3] or "n", ",") -- 默认模式为普通模式
		local _, err = pcall(
			vim.keymap.set,
			modes,
			binding[1],
			binding[2],
			{ noremap = true, silent = true, buffer = buffer, desc = binding[4] or binding.desc }
		)
		if err then
			vim.notify(err, vim.log.levels.ERROR)
			return
		end
	end
end

--- @class ConfigOpts
--- @field inherit_on_attach boolean|optvalue whether inherit on_attach function, default is true
--- @field setup (fun(conf: table): table|nil)|nil extra actions to process final config
--- @field inherit_keybindings boolean|optvalue whether inherit default keymaps, default is true
--- @field keybindings table[]|optvalue lsp keybindings
--- @field whichkey wk.Spec|(fun(): wk.Spec)|nil which-key bindings

--- create new config based on default config
--- @param append_tbl table|optvalue
--- @param opts ConfigOpts|nil
lsp.create_config = function(append_tbl, opts)
	return function()
		local util = require("lib.util")
		append_tbl = util.parse_dyn_value(append_tbl)
		append_tbl = append_tbl or {}

		opts = table.default_values(opts, {
			inherit_on_attach = true,
			inherit_keybindings = true,
		})
		util.process_dyn_table(opts, { "setup" })

		local new_attach = append_tbl.on_attach
		append_tbl.on_attach = function(client, bufnr)
			if opts.inherit_on_attach then
				lsp_default_on_attach(client, bufnr)
			end
			if opts.inherit_keybindings then
				lsp.key_attach(bufnr, lsp_default_keybindings)
				require("which-key").add({
					{ "<leader>x", group = "diagnostics", buffer = bufnr },
					{ "<leader>c", group = "lsp", buffer = bufnr },
				})
			end
			if opts.keybindings then
				lsp.key_attach(bufnr, opts.keybindings)
			end
			if opts.whichkey then
				for _, value in ipairs(opts.whichkey) do
					value.buffer = bufnr
				end
				require("which-key").add(opts.whichkey, {
					buffer = bufnr,
				})
			end
			if new_attach then
				new_attach(client, bufnr)
			end
		end
		local new_conf = vim.tbl_extend("force", lsp_default_config(), append_tbl)
		if opts.setup then
			new_conf = opts.setup(new_conf) or new_conf
		end

		return new_conf
	end
end

---@param on_attach fun(client:vim.lsp.Client, buffer)
---@param name? string
function lsp.on_attach_autocmd(on_attach, name)
	return vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(args)
			local buffer = args.buf ---@type number
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			if client and (not name or client.name == name) then
				return on_attach(client, buffer)
			end
		end,
	})
end

return lsp
