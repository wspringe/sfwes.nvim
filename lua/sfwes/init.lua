local M = {}

function M.setup(opts)
	opts = opts or {}
	local sf = require("sfwes.sf")
	sf.setup(opts)
	local commands = require("sfwes.commands")
	commands.register(opts)

	vim.api.nvim_create_autocmd("BufWritePost", {
		callback = function()
			sf.deploy()
		end,
	})
end

return M
