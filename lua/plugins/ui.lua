---@type table<string, PlugSpec>
local plugins = {}
local util = lazy_require("lib.util")

local get_header = function()
	return string.format([[


 █████╗ ██████╗  ██████╗██╗  ██╗███╗   ██╗██╗   ██╗██╗███╗   ███╗
██╔══██╗██╔══██╗██╔════╝██║  ██║████╗  ██║██║   ██║██║████╗ ████║
███████║██████╔╝██║     ███████║██╔██╗ ██║██║   ██║██║██╔████╔██║
██╔══██║██╔══██╗██║     ██╔══██║██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║  ██║██║  ██║╚██████╗██║  ██║██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
                                                                 

Arkuna's personal nvim distro

]])
end

plugins["dashboard"] = {
	"nvimdev/dashboard-nvim",
	categories = "ui",
	lazy = false,
	opts = function()
		return {
			theme = "doom",
			config = {
				-- https://patorjk.com/software/taag
				header = vim.fn.split(get_header(), "\n", true),
				center = {
					{
						icon = "  ",
						desc = "Lazy",
						action = "Lazy",
					},
					{
						icon = "  ",
						desc = "Edit config",
						action = "Neotree " .. util.config_root(),
					},
					{
						icon = "󰍉  ",
						desc = "Find files(Telescope)",
						action = "Telescope find_files",
					},
					{
						icon = "󰑓  ",
						desc = "Restore Session",
						action = "RestoreSession",
					},
					{
						icon = "󰈆  ",
						desc = "Exit Neovim",
						action = "qa",
					},
				},
				footer = function()
					local stats = util.get_startup_stats()
					return {
						string.format(
							"⚡ loaded %d/%d plugins in %.2f ms on startup",
							stats.loaded,
							stats.total,
							stats.timeMs
						),
					}
				end,
			},
		}
	end,
	config = function(_, opts)
		require("dashboard").setup(opts)

		if vim.fn.argc(-1) == 1 then
			---@diagnostic disable-next-line: param-type-mismatch
			local stat = vim.uv.fs_stat(vim.fn.argv(0))
			if stat and stat.type == "directory" then
				require("neo-tree")
			end
		end
		vim.o.laststatus = 3
	end,
}

plugins["neo-tree"] = {
	"nvim-neo-tree/neo-tree.nvim",
	categories = "ui",
	cmd = "Neotree",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	opts = function(_, opts)
		opts.close_if_last_window = true
		opts.default_component_configs = {
			indent = {
				with_expanders = true, -- if nil and file nesting is enabled, will enable expanders
				expander_collapsed = "",
				expander_expanded = "",
				expander_highlight = "NeoTreeExpander",
			},
			git_status = {
				symbols = {
					unstaged = "󰄱",
					staged = "󰱒",
				},
			},
		}
		opts.filesystem = {
			filtered_items = {
				hide_gitignored = false,
				hide_dotfiles = false,
			},
			use_libuv_file_watcher = true,
		}
	end,
	config = function(_, opts)
		require("neo-tree").setup(opts)
	end,
	keys = {
		{
			"<leader>ee",
			"<Cmd>Neotree focus<CR>",
			noremap = true,
			silent = true,
			desc = "focus NeoTree",
		},
		{
			"<leader>et",
			"<Cmd>Neotree toggle<CR>",
			noremap = true,
			silent = true,
			desc = "toggle NeoTree",
		},
	},
}

local bufferline_theme = {
	normal = {
		bg = "#1e2030",
	},
	visible = {
		bg = "#0c253c",
	},
	selected = {
		bg = "#2A3458",
	},
}

plugins["bufferline"] = {
	"akinsho/bufferline.nvim",
	categories = "ui",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"echasnovski/mini.bufremove",
	},
	event = "User Load",
	opts = function()
		local symbols = require("lib.symbols")
		local opts = {
			options = {
				close_command = function(n)
					require("mini.bufremove").delete(n, false)
				end,
				right_mouse_command = function(n)
					require("mini.bufremove").delete(n, false)
				end,
				separator_style = "thin",
				offsets = {
					{
						filetype = "neo-tree",
						text = "File Explorer",
						-- highlight = "Directory",
						text_align = "left",
					},
				},
				diagnostics = "nvim_lsp",
				diagnostics_indicator = function(_, _, diagnostics_dict, _)
					local s = " "
					for e, n in pairs(diagnostics_dict) do
						local sym = e == "error" and symbols.Error
							or (e == "warning" and symbols.Warn or symbols.Info)
						s = s .. n .. sym
					end
					return s
				end,
			},
		}

		local highlights = {
			fill = {
				bg = "",
			},
			background = bufferline_theme.normal,
			indicator_visible = bufferline_theme.visible,
			separator = bufferline_theme.normal,
		}
		for _, v in ipairs({
			"buffer",
			"error",
			"numbers",
			"close_button",
			"diagnostic",
			"warning",
			"warning_diagnostic",
			"error",
			"error_diagnostic",
			"modified",
			"duplicate",
			"hint",
			"hint_diagnostic",
			"info",
			"info_diagnostic",
		}) do
			highlights[v] = bufferline_theme.normal
			highlights[v .. "_visible"] = bufferline_theme.visible
			highlights[v .. "_selected"] = bufferline_theme.selected
		end

		opts.highlights = highlights
		return opts
	end,
	config = function(_, opts)
		require("bufferline").setup(opts)
		-- Fix bufferline when restoring a session
		vim.api.nvim_create_autocmd("BufEnter", {
			once = true,
			callback = function()
				vim.defer_fn(function()
					---@diagnostic disable-next-line: undefined-global
					local res, err = pcall(nvim_bufferline)
					if not res then
						vim.notify(err)
					end
				end, 0)
			end,
		})

		local fix_indicator = function()
			vim.cmd("highlight BufferLineIndicatorSelected guibg=" .. bufferline_theme.selected.bg)
		end
		vim.api.nvim_create_autocmd("ColorScheme", {
			pattern = "tokyonight",
			callback = fix_indicator,
		})
		fix_indicator()
	end,
	keys = {
		{ "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
		{
			"<leader>bP",
			"<Cmd>BufferLineGroupClose ungrouped<CR>",
			desc = "Delete Non-Pinned Buffers",
		},
		{ "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete Other Buffers" },
		{ "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
		{ "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
		{ "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
		{ "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
		{ "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
		{ "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
	},
}

plugins["lualine"] = {
	"nvim-lualine/lualine.nvim",
	categories = "ui",
	event = "User Load",
	opts = function()
		local symbols = require("lib.symbols")
		return {
			options = {
				theme = "auto",
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				disabled_filetypes = { statusline = { "dashboard" } },
				globalstatus = true,
			},
			extensions = { "neo-tree", "lazy" },
			sections = {
				lualine_b = { "branch", "diff" },
				lualine_c = {
					"filename",
				},
				lualine_x = {
					{
						---@diagnostic disable-next-line: undefined-field
						require("noice").api.status.mode.get,
						---@diagnostic disable-next-line: undefined-field
						cond = require("noice").api.status.mode.has,
						color = { fg = "#ff9e64" },
					},
					"copilot",
					{
						"fileformat",
						symbols = { unix = symbols.Unix, dos = symbols.Dos, mac = symbols.Mac },
					},
					"encoding",
					"filetype",
				},
			},
		}
	end,
	config = function(_, opts)
		require("lualine").setup(opts)
	end,
}

plugins["nvim-notify"] = {
	"rcarriga/nvim-notify",
	categories = "ui",
	lazy = true,
	event = "VeryLazy",
	keys = {
		{
			"<leader>un",
			function()
				require("notify").dismiss({ silent = true, pending = true })
			end,
			desc = "Dismiss All Notifications",
		},
	},
	opts = {
		stages = "slide",
		timeout = 3000,
		max_height = function()
			return math.floor(vim.o.lines * 0.75)
		end,
		max_width = function()
			return math.floor(vim.o.columns * 0.75)
		end,
		on_open = function(win)
			vim.api.nvim_win_set_config(win, { zindex = 100 })
		end,
	},
}

plugins["noice"] = {
	"folke/noice.nvim",
	categories = "ui",
	event = "VeryLazy",
	enabled = true,
	opts = {
		lsp = {
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
				["cmp.entry.get_documentation"] = true,
			},
		},
		routes = {
			{
				filter = {
					event = "msg_show",
					any = {
						{ find = "%d+L, %d+B" },
						{ find = "; after #%d+" },
						{ find = "; before #%d+" },
					},
				},
				view = "mini",
			},
		},
		presets = {
			bottom_search = true,
			command_palette = true,
			long_message_to_split = true,
			inc_rename = true,
		},
	},
	keys = {
		{
			"<S-Enter>",
			function()
				require("noice").redirect(vim.fn.getcmdline())
			end,
			mode = "c",
			desc = "Redirect Cmdline",
		},
		{
			"<leader>nl",
			function()
				require("noice").cmd("last")
			end,
			desc = "Noice Last Message",
		},
		{
			"<leader>nh",
			function()
				require("noice").cmd("history")
			end,
			desc = "Noice History",
		},
		{
			"<leader>na",
			function()
				require("noice").cmd("all")
			end,
			desc = "Noice All",
		},
		{
			"<leader>nd",
			function()
				require("noice").cmd("dismiss")
			end,
			desc = "Dismiss All",
		},
		{
			"<c-f>",
			function()
				if not require("noice.lsp").scroll(4) then
					return "<c-f>"
				end
			end,
			silent = true,
			expr = true,
			desc = "Scroll Forward",
			mode = { "i", "n", "s" },
		},
		{
			"<c-b>",
			function()
				if not require("noice.lsp").scroll(-4) then
					return "<c-b>"
				end
			end,
			silent = true,
			expr = true,
			desc = "Scroll Backward",
			mode = { "i", "n", "s" },
		},
	},
}

plugins["which-key"] = {
	"folke/which-key.nvim",
	categories = "ui",
	lazy = true,
	cmd = { "WhichKey" },
	keys = {
		{
			"<leader>",
			mode = "n",
			function()
				vim.defer_fn(require("which-key").show, vim.opt.timeoutlen:get())
			end,
			desc = "WhichKey",
		},
	},
	opts = {
		plugins = {
			marks = true,
			registers = true,
			spelling = {
				enabled = false,
			},
			presets = {
				operators = false,
				motions = true,
				text_objects = true,
				windows = true,
				nav = true,
				z = true,
				g = true,
			},
		},
		-- win = {
		-- 	border = "none",
		-- 	position = "bottom",
		-- 	-- Leave 1 line at top / bottom for bufferline / lualine
		-- 	margin = { 1, 0, 1, 0 },
		-- 	padding = { 1, 0, 1, 0 },
		-- 	winblend = 0,
		-- 	zindex = 1000,
		-- },
	},
	config = function(_, opts)
		local wk = require("which-key")
		wk.add({
			{ "<leader>b", group = "buffer" },
			{ "<leader>c", group = "lsp" },
			{ "<leader>t", group = "telescope" },
			{ "<leader>u", group = "utils" },
			{ "<leader>n", group = "noice" },
			{ "<leader>q", group = "session" },
			{ "<leader>d", group = "debug" },
			{ "<leader>e", group = "neotree" },
			{ "gs", group = "surround" },
		})
		wk.setup(opts)
	end,
}

plugins["trouble"] = {
	"folke/trouble.nvim",
	categories = "ui",
	branch = "main",
	cmd = "Trouble",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = true,
}

plugins["telescope"] = {
	"nvim-telescope/telescope.nvim",
	categories = "ui",
	cmd = { "Telescope" },
	dependencies = {
		"nvim-lua/plenary.nvim",
		"LinArcX/telescope-env.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && "
				.. "cmake --build build --config Release && "
				.. "cmake --install build --prefix build",
		},
	},
	opts = function()
		return {
			defaults = {
				initial_mode = "insert",
				mappings = {
					i = {
						["<C-j>"] = "move_selection_next",
						["<C-k>"] = "move_selection_previous",
						["<C-n>"] = "cycle_history_next",
						["<C-p>"] = "cycle_history_prev",
						["<C-c>"] = "close",
						["<C-u>"] = "preview_scrolling_up",
						["<C-d>"] = "preview_scrolling_down",
					},
				},
			},
			pickers = {
				find_files = {
					winblend = 20,
				},
			},
			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
			},
		}
	end,
	config = function(_, opts)
		local telescope = require("telescope")
		telescope.setup(opts)
		telescope.load_extension("fzf")
		telescope.load_extension("env")

		--modify layout
		local picker = require("telescope.pickers")._Picker
		local new_fn = picker.new
		---@diagnostic disable-next-line: duplicate-set-field
		picker.new = function(self, new_opts)
			new_opts = new_opts or {}
			new_opts.layout_strategy = new_opts.layout_strategy or util.get_proper_layout()
			return new_fn(self, new_opts)
		end
	end,
	keys = {
		{
			"<leader>tf",
			"<Cmd>Telescope find_files<CR>",
			desc = "find file",
			silent = true,
			noremap = true,
		},
		{
			"<leader>t<C-f>",
			"<Cmd>Telescope live_grep<CR>",
			desc = "live grep",
			silent = true,
			noremap = true,
		},
		{
			"<leader>te",
			"<Cmd>Telescope env<CR>",
			desc = "environment variables",
			silent = true,
			noremap = true,
		},
		{
			"<leader>tb",
			"<Cmd> Telescope buffers<CR>",
			desc = "buffers",
			silent = true,
			noremap = true,
		},
	},
}

plugins["dressing"] = {
	"stevearc/dressing.nvim",
	lazy = true,
	categories = "ui",
	init = function()
		---@diagnostic disable-next-line: duplicate-set-field
		vim.ui.select = function(...)
			require("lazy").load({ plugins = { "dressing.nvim" } })
			return vim.ui.select(...)
		end
		---@diagnostic disable-next-line: duplicate-set-field
		vim.ui.input = function(...)
			require("lazy").load({ plugins = { "dressing.nvim" } })
			return vim.ui.input(...)
		end
	end,
}

plugins["toggleterm"] = {
	"akinsho/toggleterm.nvim",
	categories = "ui",
	version = "*",
	cmd = { "ToggleTerm" },
    -- stylua: ignore
    keys = {
        { "<C-t>", function() require("toggleterm").toggle() end, desc = "Toggle Terminal" },
        { "<C-g>", lazy_require('lib.gitui').toggle, desc = "Toggle GiTui" }
    },
	opts = {
		direction = "float",
	},
}

return plugins
