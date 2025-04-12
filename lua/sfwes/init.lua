local M = {}
local config = require("sfwes.config")
local sf = require("sfwes.sf")
local commands = require("sfwes.commands")

function M.setup(opts)
	config.setup(opts)
	sf.setup(opts)
	commands.register(opts)

	vim.api.nvim_create_autocmd("BufWritePost", {
		callback = function()
			sf.deploy()
		end,
	})

	vim.api.nvim_create_autocmd({ "BufReadPost", "TextChanged", "TextChangedI" }, {
		callback = function(args)
			if vim.bo.ft == "apex" then
				local ns = vim.api.nvim_create_namespace("Sfwes")
				local buffer = args.buf
				local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
				for i, line in ipairs(lines) do
					if string.match(string.lower(line), "@istest") then
						vim.api.nvim_buf_set_extmark(buffer, ns, i, 0, {
							sign_text = "▶",
							virt_text_pos = "eol",
							hl_mode = "combine",
						})
					end
				end
			end
		end,
	})
end

return M
