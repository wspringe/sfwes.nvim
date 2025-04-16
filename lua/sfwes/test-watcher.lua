local M = {}

local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local spinner_index = 1
local test_ui_bufnr = nil
local test_data = {}
local timer = {}
local config = require("sfwes.config")

local function get_test_icon(status)
	if status == "running" then
		return spinner_frames[spinner_index]
	elseif status == "passed" then
		return "✔"
	elseif status == "failed" then
		return "✘"
	elseif status == "ignored" then
		return "⭘"
	end
end

local function format_test_lines()
	local lines = { "Tests:" }
	local icon = get_test_icon(test_data.status)
	table.insert(lines, string.format("  | %s %s", icon, test_data.name))

	local has_children = test_data.children and #test_data.children > 0
	if has_children then
		for i, sub in ipairs(test_data.children) do
			local sub_icon = get_test_icon(sub.status)
			local branch = (i == #test_data.children) and "  └─" or "  ├─"
			table.insert(lines, string.format("%s %s %s", branch, sub_icon, sub.name))
		end
	end
	return lines
end

local function update_test_panel()
	if not (test_ui_bufnr and vim.api.nvim_buf_is_valid(test_ui_bufnr)) then
		return
	end
	vim.bo[test_ui_bufnr].modifiable = true
	vim.api.nvim_buf_set_lines(test_ui_bufnr, 0, -1, false, format_test_lines())
	vim.bo[test_ui_bufnr].modifiable = false
end

local function mark_tests_as_running()
	test_data.status = "running"
	for _, child in ipairs(test_data.children) do
		child.status = "running"
	end
end

local function start_spinner()
	timer = vim.loop.new_timer()
	timer:start(
		0,
		50,
		vim.schedule_wrap(function()
			spinner_index = spinner_index % #spinner_frames + 1
			mark_tests_as_running()
			update_test_panel()
		end)
	)
end

local function open_test_ui_panel()
	local curr_win = vim.api.nvim_get_current_win()
	local total_width = vim.o.columns
	-- TODO: set minimum width
	local panel_width = math.floor(total_width * 0.25)

	vim.cmd("vsplit")
	test_ui_bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_win_set_buf(0, test_ui_bufnr)
	vim.bo[test_ui_bufnr].buftype = "nofile"
	vim.bo[test_ui_bufnr].bufhidden = "wipe"
	vim.bo[test_ui_bufnr].swapfile = false
	vim.bo[test_ui_bufnr].modifiable = false
	vim.bo[0].filetype = "testpanel"
	vim.wo.number = false
	vim.wo.relativenumber = false
	vim.wo.signcolumn = "no"
	vim.wo.cursorline = false
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_width(win, panel_width)

	vim.api.nvim_set_current_win(curr_win)
	update_test_panel()
end

local function test_names_salesforce_format()
	local test_names = {}
	local parent = test_data.name
	for _, child in ipairs(test_data.children) do
		table.insert(test_names, string.format("%s.%s", parent, child.name))
	end

	return table.concat(test_names, " --tests ")
end

local function run_test()
	local stdout = ""
	vim.fn.jobstart(
		config.get("sf") .. string.format(" apex run test --tests %s --json -w 60", test_names_salesforce_format()),
		{
			on_stdout = function(_, data)
				for _, line in ipairs(data) do
					stdout = stdout .. line .. "\n"
				end
			end,
			on_stderr = function(_, data, name) end,
			on_exit = function(_, data, exit_code)
				if data == 0 or data == 100 then
					if data == 0 then
						test_data.status = "success"
					else
						test_data.status = "failed"
					end

					print(vim.inspect(stdout))
					local result = vim.fn.json_decode(stdout)
					for _, obj in ipairs(result.result.tests) do
						for _, child in ipairs(test_data.children) do
							if child.name == obj.MethodName then
								if obj.Outcome == "Fail" then
									child.status = "failed"
								elseif obj.Outcome == "Pass" then
									child.status = "passed"
								-- TODO: check this status
								else
									child.status = "ignored"
								end
							end
						end
					end
				else
				end
				timer:stop()
				update_test_panel()
			end,
		}
	)
end

function M.watch(tests)
	test_data = tests
	if test_ui_bufnr == nil then
		open_test_ui_panel()
	end
	start_spinner()
	run_test()
end

return M
