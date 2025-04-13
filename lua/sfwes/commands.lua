local M = {}
local _sf = require("sfwes.sf")
local _config = require("sfwes.config")

function M.setup(config, sf)
	_sf = sf
	_config = config
end

function M.register()
	vim.api.nvim_create_user_command(_config.get("ns_name") .. "SaveAndDeploy", function()
		vim.cmd("write")
		_sf.deploy()
	end, {})

	vim.api.nvim_create_user_command(_config.get("ns_name") .. "RefreshMetadata", function()
		_sf.refresh()
	end, {})

	vim.api.nvim_create_user_command(_config.get("ns_name") .. "RetrieveMetadata", function(opts)
		_sf.retrieve(opts.fargs[1], opts.fargs[2])
	end, {
		nargs = "+",
	})

	vim.api.nvim_create_user_command(_config.get("ns_name") .. "Create", function(opts)
		_sf.create(opts.fargs[1], opts.fargs[2])
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

	vim.api.nvim_create_user_command(_config.get("ns_name") .. "RunTest", function(opts)
		local extmarks = vim.api.nvim_buf_get_extmarks(0, _config.get_namespace(), 0, -1, {})
		local marked_lines = {}
		for _, extmark in ipairs(extmarks) do
			table.insert(marked_lines, extmark[2] + 1)
		end
		local cursor_pos = vim.api.nvim_win_get_cursor(0)
		local cursor_line = cursor_pos[1]

		if vim.tbl_contains(marked_lines, cursor_line) then
			local current_line = vim.api.nvim_get_current_line()
			local last_word = current_line:match("(%w+)%W*$")
			local current_file_name = vim.fn.expand("%:t"):match("^(.*)%.")
			if last_word == current_file_name then
				_sf.run_tests(current_file_name)
			else
				_sf.run_test(current_file_name, last_word)
			end
		end
	end, {})
end

return M
