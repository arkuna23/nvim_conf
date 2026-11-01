local M = {}
local selections = {}
local selecting = false

local function larger(node, previous)
	while node do
		local range = { node:range() }
		if not previous or not vim.deep_equal(range, previous) then
			return node, range
		end
		node = node:parent()
	end
end

local function scope_parent(node, bufnr, lang)
	local query = vim.treesitter.query.get(lang, "locals")
	if query then
		local scopes = {}
		local root = node:tree():root()
		for id, capture in query:iter_captures(root, bufnr) do
			if query.captures[id] == "local.scope" then
				scopes[capture:id()] = true
			end
		end
		local parent = node:parent()
		while parent do
			if scopes[parent:id()] then
				return parent
			end
			parent = parent:parent()
		end
	end
	local parent = node:parent()
	while parent and not parent:named() do
		parent = parent:parent()
	end
	return parent
end

local function show(range)
	local sr, sc, er, ec = unpack(range)
	if ec == 0 and er > sr then
		er = er - 1
		ec = #vim.api.nvim_buf_get_lines(0, er, er + 1, false)[1]
	end
	local line = vim.api.nvim_buf_get_lines(0, er, er + 1, false)[1] or ""
	local col = ec > 0 and vim.fn.byteidx(line, vim.fn.charidx(line, ec - 1)) or 0
	selecting = true
	vim.cmd.normal({
		args = { vim.api.nvim_replace_termcodes("<Esc>", true, false, true) },
		bang = true,
	})
	vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
	vim.cmd.normal({ args = { "v" }, bang = true })
	vim.api.nvim_win_set_cursor(0, { er + 1, math.max(col, 0) })
	selecting = false
end

function M.select(action)
	local bufnr = vim.api.nvim_get_current_buf()
	local tick = vim.api.nvim_buf_get_changedtick(bufnr)
	local state = selections[bufnr]
	if not state or state.tick ~= tick or vim.fn.mode() ~= "v" then
		local node = vim.treesitter.get_node()
		if not node then
			return
		end
		state = { tick = tick, nodes = { node } }
		selections[bufnr] = state
	elseif action == "shrink" then
		if #state.nodes > 1 then
			table.remove(state.nodes)
		end
	else
		local node = state.nodes[#state.nodes]
		local parent = node:parent()
		if action == "scope" then
			local parser = vim.treesitter.get_parser(bufnr)
			local language_tree = parser:language_for_range({ node:range() })
			parent = scope_parent(node, bufnr, language_tree:lang())
		end
		parent = larger(parent, { node:range() })
		if parent then
			state.nodes[#state.nodes + 1] = parent
		end
	end
	show({ state.nodes[#state.nodes]:range() })
end

function M.attach(bufnr)
	if not vim.api.nvim_buf_is_loaded(bufnr) or vim.bo[bufnr].buftype ~= "" then
		return
	end
	local lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype)
	if not lang then
		return
	end
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
	if not ok or not parser then
		return
	end
	if lang ~= "latex" then
		vim.treesitter.start(bufnr, lang)
	end
	if vim.treesitter.query.get(lang, "indents") then
		vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end
	for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
		if
			vim.wo[win].foldmethod ~= "expr"
			or vim.wo[win].foldexpr ~= "v:lua.vim.treesitter.foldexpr()"
		then
			vim.wo[win].foldmethod = "expr"
			vim.wo[win].foldexpr = "v:lua.vim.treesitter.foldexpr()"
			vim.wo[win].foldlevel = 99
			vim.wo[win].foldcolumn = "1"
		end
	end
	vim.keymap.set("n", "<CR>", function()
		M.select("expand")
	end, { buffer = bufnr, desc = "Select syntax node" })
	vim.keymap.set("x", "<CR>", function()
		M.select("expand")
	end, { buffer = bufnr, desc = "Expand syntax selection" })
	vim.keymap.set("x", "<BS>", function()
		M.select("shrink")
	end, { buffer = bufnr, desc = "Shrink syntax selection" })
	vim.keymap.set("x", "<Tab>", function()
		M.select("scope")
	end, { buffer = bufnr, desc = "Select syntax scope" })
end

function M.setup(parsers)
	vim.treesitter.language.register("json", "jsonc")
	local group = vim.api.nvim_create_augroup("ConfigTreesitter", { clear = true })
	vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
		group = group,
		callback = function(args)
			M.attach(args.buf)
		end,
	})
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "BufWipeout" }, {
		group = group,
		callback = function(args)
			selections[args.buf] = nil
		end,
	})
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		callback = function(args)
			if not selecting and vim.v.event.old_mode == "v" and vim.v.event.new_mode ~= "v" then
				selections[args.buf] = nil
			end
		end,
	})
	local function attach_all()
		for _, buf in ipairs(vim.api.nvim_list_bufs()) do
			M.attach(buf)
		end
	end
	attach_all()
	require("nvim-treesitter")
		.install(parsers, { max_jobs = 4 })
		:await(vim.schedule_wrap(function(err)
			if err then
				vim.notify(tostring(err), vim.log.levels.ERROR)
			end
			attach_all()
		end))
end

return M
