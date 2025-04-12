local M = {}
local sf = require("sfwes.sf")
local config = require("sfwes.config")

function M.register()
	vim.api.nvim_create_user_command(ns_name .. "SaveAndDeploy", function()
		vim.cmd("write")
		sf.deploy()
	end, {})

	vim.api.nvim_create_user_command(ns_name .. "RefreshMetadata", function()
		sf.refresh()
	end, {})

	vim.api.nvim_create_user_command(ns_name .. "RetrieveMetadata", function(opts)
		sf.retrieve(opts.fargs[1], opts.fargs[2])
	end, {
		nargs = "+",
	})

	vim.api.nvim_create_user_command(ns_name .. "Create", function(opts)
		sf.create(opts.fargs[1], opts.fargs[2])
	end, {
		nargs = "+",
		complete = function(arg_lead, cmd_line)
			local args = vim.split(cmd_line, "%s+")
			local args_index = #args - 1
			if args_index == 1 then
				return { "apex", "trigger", "lwc" }
			elseif args_index == 3 then
				local dir_lead = arg_lead == "" and "*" or arg_lead .. "*/"
				local dirs = vim.fn.globpath(vim.fn.getcwd(), dir_lead, false, true)

				local dir_suggestions = {}
				for _, dir in ipairs(dirs) do
					if vim.fn.isdirectory(dir) then
						table.insert(dir_suggestions, dir)
					end
				end

				return dir_suggestions
			else
				return {}
			end
		end,
	})
end

vim.api.nvim_create_user_command(ns_name .. "RunTest", function(opts)
	local extmarks = vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {})
	local marked_lines = {}
	for _, extmark in ipairs(extmarks) do
		table.insert(marked_lines, extmark[1] + 1)
	end
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local cursor_line = cursor_pos[1]

	if marked_lines[cursor_line] ~= nil then
		local current_line = vim.api.nvim_get_current_line()
		local last_word = current_line:match("(%w+)%W*$")
		local current_file_name = vim.fn.expand("%:t"):match("^(.*)%.")
		sf.run_test(current_file_name, last_word)
	end
end, opts)

return M
