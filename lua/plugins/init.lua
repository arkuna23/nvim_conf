local utils = require 'utils'

-- User Load: triggered when editing a file
vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        local function _trigger()
            vim.api.nvim_exec_autocmds("User", { pattern = "Load" })
        end

        if vim.bo.filetype == "dashboard" then
            vim.api.nvim_create_autocmd("BufRead", {
                once = true,
                callback = _trigger,
            })
        else
            _trigger()
        end
    end,
})

local plugins = utils.mergeTables(
    require 'plugins.ui',
    require 'plugins.lsp'
)
return utils.table2array(plugins)
