local utils = require('utils')
local symbols = require('symbols')

local plugins = {}

plugins['dashboard'] = {
    "nvimdev/dashboard-nvim",
    lazy = false,
    opts = {
        theme = "doom",
        config = {
            -- https://patorjk.com/software/taag
            header = utils.readFileLines(utils.configRoot .. "/header.txt"),
            center = {
                {
                    icon = "  ",
                    desc = "Lazy Profile",
                    action = "Lazy profile",
                },
                {
                    icon = "  ",
                    desc = "Edit preferences",
                    action = string.format("edit %s/lua/custom/init.lua", utils.configRoot),
                },
                {
                    icon = "  ",
                    desc = "Mason",
                    action = "Mason",
                },
                {
                    icon = "  ",
                    desc = "About IceNvim",
                    action = "lua require('plugins.utils').about()",
                },
            },
        },
    },
    config = function(_, opts)
        require("dashboard").setup(opts)
    end,
}

plugins['neo-tree'] = {
    "nvim-neo-tree/neo-tree.nvim",
    lazy = true,
    event = { "User Load" },
    cmd = "Neotree",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },
    opts = {
        auto_open = true,
        update_to_buf_dir = {
            enable = true,
            auto_open = true,
        },
        view = {
            width = 30,
            side = "left",
            auto_resize = true,
        }
    },
    config = function(_, opts)
        require("neo-tree").setup(opts)
    end,
}

plugins['mini.bufremove'] = {
  "echasnovski/mini.bufremove",

  keys = {
    {
      "<leader>bd",
      function()
        local bd = require("mini.bufremove").delete
        if vim.bo.modified then
          local choice = vim.fn.confirm(("Save changes to %q?"):format(vim.fn.bufname()), "&Yes\n&No\n&Cancel")
          if choice == 1 then -- Yes
            vim.cmd.write()
            bd(0)
          elseif choice == 2 then -- No
            bd(0, true)
          end
        else
          bd(0)
        end
      end,
      desc = "Delete Buffer",
    },
    -- stylua: ignore
    { "<leader>bD", function() require("mini.bufremove").delete(0, true) end, desc = "Delete Buffer (Force)" },
  },
}

plugins['bufferline'] = {
    "akinsho/bufferline.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    event = "User Load",
    opts = {
        options = {
                close_command = function(n) require("mini.bufremove").delete(n, false) end,
        -- stylua: ignore
                right_mouse_command = function(n) require("mini.bufremove").delete(n, false) end,
            separator_style = "thin",
            offsets = {
                {
                    filetype = "neo-tree",
                    text = "File Explorer",
                    highlight = "Directory",
                    text_align = "left",
                },
            },
            diagnostics = "nvim_lsp",
            diagnostics_indicator = function(_, _, diagnostics_dict, _)
                local s = " "
                for e, n in pairs(diagnostics_dict) do
                    local sym = e == "error" and symbols.Error or (e == "warning" and symbols.Warn or symbols.Info)
                    s = s .. n .. sym
                end
                return s
            end,
        },
    },
    config = function(_, opts)
    require("bufferline").setup(opts)
    -- Fix bufferline when restoring a session
    vim.api.nvim_create_autocmd("BufAdd", {
      callback = function()
        vim.schedule(function()
          pcall(nvim_bufferline)
        end)
      end,
    })
  end,
    keys = {
        { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
        { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
        { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "Delete Other Buffers" },
        { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
        { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
        { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
        { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
        { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
        { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
}
}

plugins['lualine'] = {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "arkav/lualine-lsp-progress",
    },
    event = "User Load",
    main = "lualine",
    opts = {
        options = {
            theme = "auto",
            component_separators = { left = "", right = "" },
            section_separators = { left = "", right = "" },
            disabled_filetypes = { "undotree", "diff" },
        },
        extensions = { "neo-tree", "lazy" },
        sections = {
            lualine_b = { "branch", "diff" },
            lualine_c = {
                "filename",
                {
                    "lsp_progress",
                    spinner_symbols = {
                        symbols.Dice1,
                        symbols.Dice2,
                        symbols.Dice3,
                        symbols.Dice4,
                        symbols.Dice5,
                        symbols.Dice6,
                    },
                },
            },
            lualine_x = {
                "filesize",
                {
                    "fileformat",
                    symbols = { unix = symbols.Unix, dos = symbols.Dos, mac = symbols.Mac },
                },
                "encoding",
                "filetype",
            },
        },
    },
}

plugins['nvim-notify'] = {
    "rcarriga/nvim-notify",
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
        stages = "static",
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
    }
}

plugins['noice'] = {
    "folke/noice.nvim",
    event = "VeryLazy",
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
    -- stylua: ignore
    keys = {
        { "<S-Enter>",   function() require("noice").redirect(vim.fn.getcmdline()) end,                 mode = "c",                 desc = "Redirect Cmdline" },
        { "<leader>snl", function() require("noice").cmd("last") end,                                   desc = "Noice Last Message" },
        { "<leader>snh", function() require("noice").cmd("history") end,                                desc = "Noice History" },
        { "<leader>sna", function() require("noice").cmd("all") end,                                    desc = "Noice All" },
        { "<leader>snd", function() require("noice").cmd("dismiss") end,                                desc = "Dismiss All" },
        { "<c-f>",       function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end,  silent = true,              expr = true,              desc = "Scroll Forward",  mode = { "i", "n", "s" } },
        { "<c-b>",       function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true,              expr = true,              desc = "Scroll Backward", mode = { "i", "n", "s" } },
    },
}

plugins['which-key'] = {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function(_, opts)
        local wk = require('which-key')
        wk.setup(opts)
        wk.register({
            ["<leader>b"] = { name = "+buffer" },
            ["<leader>c"] = { name = "+comment" },
            ["<leader>g"] = { name = "+git" },
            ["<leader>h"] = { name = "+hop" },
            ["<leader>l"] = { name = "+lsp" },
            ["<leader>t"] = { name = "+telescope" },
            ["<leader>u"] = { name = "+utils" },
        })
    end
}

plugins['nvim-transparent'] = {
    "xiyaowong/nvim-transparent",
    enable = false,
    opts = {
        extra_groups = {
            "NvimTreeNormal",
            "NvimTreeNormalNC",
        },
    },
    config = function(_, opts)
        local autogroup = vim.api.nvim_create_augroup("transparent", { clear = true })
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = autogroup,
            callback = function()
                local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })
                local foreground = string.format("#%06x", normal_hl.fg)
                local background = string.format("#%06x", normal_hl.bg)
                vim.api.nvim_command("highlight default ColorNormal guifg=" .. foreground .. " guibg=" .. background)

                require("transparent").clear()
            end,
        })
        -- Enable transparent by default
        local transparent_cache = vim.fn.stdpath "data" .. "/transparent_cache"
        local f = io.open(transparent_cache, "r")
        if f ~= nil then
            f:close()
        else
            f = io.open(transparent_cache, "w")
            f:write "true"
            f:close()
        end

        require("transparent").setup(opts)

        local old_get_hl = vim.api.nvim_get_hl
        vim.api.nvim_get_hl = function(ns_id, opt)
            if opt.name == "Normal" then
                local attempt = old_get_hl(0, { name = "IceNormal" })
                if next(attempt) ~= nil then
                    opt.name = "IceNormal"
                end
            end
            return old_get_hl(ns_id, opt)
        end
    end,
}

plugins['trouble'] = {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    branch = "dev",
    keys = {
        {
            "<leader>xx",
            function() require("trouble").toggle("diagnostics") end,
            desc = "Diagnostics (Trouble)"
        },
        {
            "<leader>xX",
            function() require("trouble").toggle("workspace_diagnostics") end,
            desc = "Buffer Diagnostics (Trouble)"
        },
        {
            "<leader>gR",
            function() require("trouble").toggle("lsp_references") end,
            desc = "LSP references/definitions/... (Trouble)",
        },
        {
            "<leader>xL",
            function() require("trouble").toggle("loclist") end,
            desc = "Location List (Trouble)"
        },
        {
            "<leader>xQ",
            function() require("trouble").toggle("quickfix") end,
            desc = "Quickfix List (Trouble)"
        },
        {
            "[q",
            function()
                if require("trouble").is_open() then
                    require("trouble").prev({ skip_groups = true, jump = true })
                else
                    local ok, err = pcall(vim.cmd.cprev)
                    if not ok then
                        vim.notify(err, vim.log.levels.ERROR)
                    end
                end
            end,
            desc = "Previous Trouble/Quickfix Item",
        },
    },
}

return plugins
