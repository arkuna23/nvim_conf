local utils = require 'utils'

local plugins = utils.mergeTables(
    require 'plugins.ui'
)
return utils.table2array(plugins)
