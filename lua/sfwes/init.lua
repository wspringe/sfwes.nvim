local M = {}

function M.setup(opts)
	print("testing")
	opts = opts or {}
	local sf = opts.sf

	vim.keymap.set("n", "<Leader>h", function()
		if opts.name then
			print("hello, " .. opts.name)
		else
			print("hello")
		end
	end)

	vim.api.nvim_create_autocmd("BufWritePost", {
		callback = function()
			print("testing after write? +ft " .. vim.bo.ft)
			if vim.bo.ft == "apex" then
				local job = vim.fn.jobstart(sf .. " project deploy start", {
					on_stdout = function(jobid, data, event)
						print(data)
					end,
					on_stderr = function(jobid, data, event)
						print(data)
					end,
				})
			end
		end,
	})
end

return M
