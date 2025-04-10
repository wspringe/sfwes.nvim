local M = {}

function M.setup(opts)
	opts = opts or {}
	local sf = opts.sf

	vim.keymap.set("n", "<Leader>h", function()
		if opts.name then
			print("hello, " .. opts.name)
		else
			print("hello")
		end
	end)

	local stdout = ""
	vim.api.nvim_create_autocmd("BufWritePost", {
		callback = function()
			if vim.bo.ft == "apex" then
				local spinner = require("sfwes.indicator")
				spinner.start()
				local job = vim.fn.jobstart(sf .. " project deploy start --json", {
					on_stdout = function(_, data, name)
						for _, line in ipairs(data) do
							stdout = stdout .. line .. "\n"
						end
					end,
					on_stderr = function(_, data, name) end,
					on_exit = function(_, data, exit_code)
						if data == 0 then
							spinner.stop("success")
						else
							spinner.stop("error")
						end
						-- print(stdout)
					end,
				})
			end
		end,
	})
end

return M
