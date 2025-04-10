-- for testing purposes
local ok, lualine = pcall(require, "lualine")
if not ok then
	return
end

local indicator = require("sfwes.indicator")
local config = lualine.get_config()
table.insert(config.sections.lualine_c, indicator.component)
lualine.setup(config)
