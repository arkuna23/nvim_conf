local utils = require('utils')
local symbols = require('symbols')

local header = [[
                      ▄                     ▄ ▀ ■                              
      ▄ ▀               ▀▄    ▄■▀▀▀■▄      █                ▄■▀▀▀■▄            
 ░   █▄     ▓▄     ░    ▄█▌  ▀       ▓▄     ▀▀███▄▄     ░ ▄█▄     ▓█▄          
      ▀███▄ ▓██▄     ▄▄███▄▄▀    ░   ▓██▄▄▄▄▄▄▄█████▄ ░ ▄██▀██▄ ░ ▓██▓  ░     ▄
▄████▀▀▀▀▀▀ ▓██▓  ▓████▀█▓▓▓█  ▄▄▄▄▄▄▓██▓ ▓██▓  ▓██▓▀ ▄██▓   ▓██▄ ▓██▓ ░░░  ▄█▓
 ▀▀▀▀▀▀▓▓▓▓▄▀▓▓▓▀▀▓▓▓▄   ▀▀▀  █▓▓▓▀  ▓▓▓▓ ▓▓▓▓▀▀▓▓▓▄▄ ▓▓▓▓ ░ ▓▓▓▓ ▓▓▓▓ ░░░ ▓▓▓▓
▒▒▒▒▒  ▐▒▒▒▒█▐▒▒  ▐▒▒▒▒ ▓▓▓▓▓▐▒▒▒▒ ░ ▒▒▒▒ ▒▒▒▒  ▐▒▒▒▒█▄▒▒▒ ░ ▒▒▒▒ ▒▒▒▒ ░░░ ▒▒▒▒
░░░░░ ░ ░░░░░▌░░ ░ ░░░░░░░░░░▐░░░░ ░ ░░░░ ░░░░ ░ ░░░░░░░░░ ░ ░░░░ ░░░░  ▄  ░░░░
▒▒▒▒▒ ░ ▒▒▒▒▒▌▒▒ ░ ▒▒▒▒▒▄▒▒▒▒▒▒▒▒▒ ░ ▒▒▒▒ ▒▒▒▒ ░ ▒▒▒▒▒▌▒▒▒ ░ ▒▒▒▒ ▒▒▓▀▄███▄▀▓▒▒
▐▓▓▓▓ ░▐▓▓▓▓▓▓▓▓ ░▐▓▓▓▓▓▌▓▓▓▓▐▓▓▓▓▌  ▓▓▓▓ ▓▓▓▓ ░▐▓▓▓▓▓▓▓▓▓ ░ ▓▓▓▓ ▓▓▓▓▓▀ ▀▓▓▓▓▓
 ▀██▓ ▄█▓██▀▄██▀  ▓████▓███▀  ▓███▓▄▄▓██▓▄▓█▀   ▓███▓ ▀██▓   ▓██▀ ▓██▀ ░ ░ ▀██▓
░  ▀▄██▀▀   █▀   ▄█▓██▀ █▀  ░  █████▀▀▀   ▀  ░ ▐██▓█▌ ░ ▀██▄██▀ ░ ▓▀   ░     ▀█
  ▄▀▀    ░     ▄███▀▀  ░ ▀■▄▄■▀ ▀▀████▄▄▄■▀  ░  ▀▀███▄▄▄▄▄██▀ Eboy             
  ▀▄▄■▀     ■▀▀                                     ▀▀▀▀▀▀                     
                          S   K   i   D   R   O   W                            

                  ->  T H E   L E A D i N G   F O R C E   <                    

]]

local plugins = {}

plugins['dashboard'] = {
    "nvimdev/dashboard-nvim",
    lazy = false,
    opts = {
        theme = "doom",
        config = {
            -- https://patorjk.com/software/taag
            header = utils.spiltString(header, '\n'),
            center = {
                {
                    icon = "  ",
                    desc = "Lazy Profile",
                    action = "Lazy profile",
                },
                {
                    icon = "  ",
                    desc = "Edit preferences   ",
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

plugins['bufferline'] = {
    "akinsho/bufferline.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    event = "User Load",
    opts = {
        options = {
            close_command = ":BufferLineClose %d",
            right_mouse_command = ":BufferLineClose %d",
            separator_style = "thin",
            offsets = {
                {
                    filetype = "NvimTree",
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
        vim.api.nvim_create_user_command("BufferLineClose", function(buffer_line_opts)
            local bufnr = 1 * buffer_line_opts.args
            local buf_is_modified = vim.api.nvim_buf_get_option(bufnr, "modified")

            local bdelete_arg
            if bufnr == 0 then
                bdelete_arg = ""
            else
                bdelete_arg = " " .. bufnr
            end
            local command = "bdelete!" .. bdelete_arg
            if buf_is_modified then
                local option = vim.fn.confirm("File is not saved. Close anyway?", "&Yes\n&No", 2)
                if option == 1 then
                    vim.cmd(command)
                end
            else
                vim.cmd(command)
            end
        end, { nargs = 1 })

        require("bufferline").setup(opts)
    end,
    keys = {
        { "<leader>bc", "<Cmd>BufferLinePickClose<CR>", desc = "pick close", silent = true, noremap = true },
        -- <esc> is added in case current buffer is the last
        { "<leader>bd", "<Cmd>BufferLineClose 0<CR><ESC>", desc = "close current buffer", silent = true, noremap = true },
        { "<leader>bh", "<Cmd>BufferLineCyclePrev<CR>", desc = "prev buffer", silent = true, noremap = true },
        { "<leader>bl", "<Cmd>BufferLineCycleNext<CR>", desc = "next buffer", silent = true, noremap = true },
        { "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", desc = "close others", silent = true, noremap = true },
        { "<leader>bp", "<Cmd>BufferLinePick<CR>", desc = "pick buffer", silent = true, noremap = true },
    },
}

plugins['nvim-tree'] = {
    "nvim-tree/nvim-tree.lua",
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {
        on_attach = function(bufnr)
            local api = require "nvim-tree.api"
            local opt = {
                buffer = bufnr,
                noremap = true,
                silent = true,
            }

            api.config.mappings.default_on_attach(bufnr)

            require("core.utils").group_map({
                edit = {
                    "n",
                    "<CR>",
                    function()
                        local node = api.tree.get_node_under_cursor()
                        if node.name ~= ".." and node.fs_stat.type == "file" then
                            -- Taken partially from:
                            -- https://support.microsoft.com/en-us/windows/common-file-name-extensions-in-windows-da4a4430-8e76-89c5-59f7-1cdbbc75cb01
                            --
                            -- Not all are included for speed's sake
                            local extensions_opened_externally = {
                                "avi",
                                "bmp",
                                "doc",
                                "docx",
                                "exe",
                                "flv",
                                "gif",
                                "jpg",
                                "jpeg",
                                "m4a",
                                "mov",
                                "mp3",
                                "mp4",
                                "mpeg",
                                "mpg",
                                "pdf",
                                "png",
                                "ppt",
                                "pptx",
                                "psd",
                                "pub",
                                "rar",
                                "rtf",
                                "tif",
                                "tiff",
                                "wav",
                                "xls",
                                "xlsx",
                                "zip",
                            }
                            if table.find(extensions_opened_externally, node.extension) then
                                api.node.run.system()
                                return
                            end
                        end

                        api.node.open.edit()
                    end,
                },
                vertical_split = { "n", "V", api.node.open.vertical },
                horizontal_split = { "n", "H", api.node.open.horizontal },
                toggle_hidden_file = { "n", ".", api.tree.toggle_hidden_filter },
                reload = { "n", "<F5>", api.tree.reload },
                create = { "n", "a", api.fs.create },
                remove = { "n", "d", api.fs.remove },
                rename = { "n", "r", api.fs.rename },
                cut = { "n", "x", api.fs.cut },
                copy = { "n", "y", api.fs.copy.node },
                paste = { "n", "p", api.fs.paste },
                system_run = { "n", "s", api.node.run.system },
                show_info = { "n", "i", api.node.show_info_popup },
            }, opt)
        end,
        git = {
            enable = false,
        },
        update_cwd = true,
        update_focused_file = {
            enable = true,
            update_cwd = true,
        },
        filters = {
            dotfiles = false,
            custom = { "node_modules", ".git/" },
            exclude = { ".gitignore" },
        },
        view = {
            width = 30,
            side = "left",
            number = false,
            relativenumber = false,
            signcolumn = "yes",
        },
        actions = {
            open_file = {
                resize_window = true,
                quit_on_open = true,
            },
        },
    },
    config = function(_, opts)
        require("nvim-tree").setup(opts)

        -- automatically close
        vim.cmd "autocmd BufEnter * ++nested if winnr('$') == 1 && bufname() == 'NvimTree_' . tabpagenr() | quit | endif"
    end,
    keys = {
        { "<leader>uf", "<Cmd>NvimTreeToggle<CR>", desc = "toggle nvim tree", silent = true, noremap = true },
    },
}

return plugins
