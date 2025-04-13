local M = {}
local _config = require("sfwes.config")
local _sf = require("sfwes.sf")
local _commands = require("sfwes.commands")

function M.setup(opts)
	_config.setup(opts)
	_sf.setup(_config)
	_commands.setup(_config, _sf)
	_commands.register()

	vim.api.nvim_create_autocmd("BufWritePost", {
		callback = function()
			_sf.deploy()
		end,
	})

	vim.api.nvim_create_autocmd({ "BufReadPost", "TextChanged", "TextChangedI" }, {
		callback = function(args)
			if vim.bo.ft == "apex" then
				local buffer = args.buf
				local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
				for i, line in ipairs(lines) do
					if string.match(string.lower(line), "@istest") then
						vim.api.nvim_buf_set_extmark(buffer, _config.get_namespace(), i, 0, {
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
