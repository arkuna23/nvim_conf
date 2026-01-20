---@type table<string, PlugSpec>
local plugins = {}

plugins["nvim-dap"] = {
	"mfussenegger/nvim-dap",
	recommended = true,
	categories = "dap",
	desc = "Debugging support. Requires language specific adapters to be configured. (see lang extras)",
	dependencies = {

		-- fancy UI for the debugger
		{
			"rcarriga/nvim-dap-ui",
			dependencies = { "nvim-neotest/nvim-nio" },
            -- stylua: ignore
            keys = {
                { "<leader>du", function() require("dapui").toggle({}) end, desc = "Dap UI" },
                { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },
            },
			opts = {},
			config = function(_, opts)
				local dap = require("dap")
				local dapui = require("dapui")
				dapui.setup(opts)
				dap.listeners.after.event_initialized["dapui_config"] = function()
					dapui.open({})
				end
				dap.listeners.before.event_terminated["dapui_config"] = function()
					dapui.close({})
				end
				dap.listeners.before.event_exited["dapui_config"] = function()
					dapui.close({})
				end
			end,
		},
		-- virtual text for the debugger
		{
			"theHamsta/nvim-dap-virtual-text",
		},
		-- mason.nvim integration
		{
			"jay-babu/mason-nvim-dap.nvim",
			dependencies = "mason.nvim",
			cmd = { "DapInstall", "DapUninstall" },
			opts = {
				-- Makes a best effort to setup the various debuggers with
				-- reasonable debug configurations
				automatic_installation = true,

				-- You can provide additional configuration to the handlers,
				-- see mason-nvim-dap README for more information
				handlers = {},

				-- You'll need to check that you have the required things installed
				-- online, please don't ask me how to install them :)
				ensure_installed = {
					-- Update this to ensure that you have the debuggers for the langs you want
				},
			},
		},

		-- VsCode launch.json parser
		{
			"folke/neoconf.nvim",
		},
	},
	opts = function()
		---@diagnostic disable undefined-field
		local dap = require("dap")
		local mason_registry = require("mason-registry")

		local codelldb_root = vim.fn.expand("$MASON/packages/codelldb") .. "/extension/"
		local codelldb_path = codelldb_root .. "adapter/codelldb"
		local liblldb_path = codelldb_root .. "lldb/lib/liblldb.so"
		local codelldb_conf = {
			{
				type = "codelldb",
				request = "launch",
				name = "Launch file",
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
				cwd = "${workspaceFolder}",
			},
			{
				type = "codelldb",
				request = "attach",
				name = "Attach to process",
				pid = require("dap.utils").pick_process,
				cwd = "${workspaceFolder}",
			},
		}

		local kt_conf = {
			{
				type = "kotlin",
				request = "launch",
				name = "This file",
				-- may differ, when in doubt, whatever your project structure may be,
				-- it has to correspond to the class file located at `build/classes/`
				-- and of course you have to build before you debug
				mainClass = function()
					local root = vim.fs.find(
						"src",
						{ path = vim.uv.cwd(), upward = true, stop = vim.env.HOME }
					)[1] or ""
					local fname = vim.api.nvim_buf_get_name(0)
					-- src/main/kotlin/websearch/Main.kt -> websearch.MainKt
					return fname
						:gsub(root, "")
						:gsub("main/kotlin/", "")
						:gsub(".kt", "Kt")
						:gsub("/", ".")
						:sub(2, -1)
				end,
				projectRoot = "${workspaceFolder}",
				jsonLogFile = "",
				enableJsonLogging = false,
			},
			{
				-- Use this for unit tests
				-- First, run
				-- ./gradlew --info cleanTest test --debug-jvm
				-- then attach the debugger to it
				type = "kotlin",
				request = "attach",
				name = "Attach to debugging session",
				port = 5005,
				args = {},
				projectRoot = vim.fn.getcwd,
				hostName = "localhost",
				timeout = 2000,
			},
		}

		dap.adapters = {
			codelldb = {
				type = "server",
				port = "${port}",
				host = "127.0.0.1",
				executable = {
					command = codelldb_path,
					args = { "--liblldb", liblldb_path, "--port", "${port}" },
				},
			},
			kotlin = {
				type = "executable",
				command = "kotlin-debug-adapter",
				options = { auto_continue_if_many_stopped = false },
			},
		}

		dap.configurations = {
			c = codelldb_conf,
			cpp = codelldb_conf,
			kotlin = kt_conf,
		}

		---@diagnostic enable undefined-field
	end,
    -- stylua: ignore
    ---@diagnostic disable: undefined-field
    keys = {
        { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
        { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
        { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
---@diagnostic disable-next-line: undefined-global
        { "<leader>da", function() require("dap").continue({ before = get_args }) end, desc = "Run with Args" },
        { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
        { "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
        { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
        { "<leader>dj", function() require("dap").down() end, desc = "Down" },
        { "<leader>dk", function() require("dap").up() end, desc = "Up" },
        { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
        { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
        { "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
        { "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
        { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
        { "<leader>ds", function() require("dap").session() end, desc = "Session" },
        { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
        { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
    },
	---@diagnostic enable: undefined-field
	config = function() end,
}

return plugins
