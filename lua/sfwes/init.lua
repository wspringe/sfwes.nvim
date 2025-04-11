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

	vim.api.nvim_create_autocmd("BufWritePost", {
		callback = function()
			if vim.bo.ft == "apex" then
				local ns = vim.api.nvim_create_namespace("sfwes")
				vim.diagnostic.reset(ns, 0)
				local spinner = require("sfwes.indicator")
				spinner.start()

				local stdout = ""
				local job =
					vim.fn.jobstart(sf .. string.format(" project deploy start --json -d %s", vim.fn.expand("%")), {
						on_stdout = function(_, data)
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
								local result = vim.fn.json_decode(stdout)
								local diagnostics = {}
								for _, obj in ipairs(result.result.details.componentFailures) do
									table.insert(diagnostics, {
										lnum = (obj.lineNumber - 1),
										col = obj.columnNumber - 1,
										message = obj.problem,
										severity = vim.diagnostic.severity.ERROR,
										source = "sfwes",
									})
								end
								print(vim.inspect(diagnostics))
								vim.diagnostic.set(ns, 0, diagnostics)
							end
						end,
					})
			end
		end,
	})
end

return M
