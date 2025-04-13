local M = {}
local _config = require("sfwes.config")

function M.setup(config)
	_config = config
end

function M.deploy()
	if vim.bo.ft == "apex" then
		vim.diagnostic.reset(_config.get_namespace(), 0)
		local spinner = require("sfwes.indicator")
		spinner.start()

		local stdout = ""
		local job = vim.fn.jobstart(
			_config.get("sf") .. string.format(" project deploy start --json -d %s", vim.fn.expand("%")),
			{
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
								lnum = obj.lineNumber - 1,
								col = obj.columnNumber - 1,
								message = obj.problem,
								severity = vim.diagnostic.severity.ERROR,
								source = "sfwes",
							})
						end
						vim.diagnostic.set(_config.get_namespace(), 0, diagnostics)
					end
				end,
			}
		)
	end
end

function M.refresh()
	vim.diagnostic.reset(_config.get_namespace(), 0)
	local spinner = require("sfwes.indicator")
	spinner.start()

	local stdout = ""
	local job = vim.fn.jobstart(
		_config.get("sf") .. string.format(" project retrieve start --json -d %s", vim.fn.expand("%")),
		{
			on_stdout = function(_, data)
				for _, line in ipairs(data) do
					stdout = stdout .. line .. "\n"
				end
			end,
			on_stderr = function(_, data, name) end,
			on_exit = function(_, data, exit_code)
				if data == 0 then
					spinner.stop("success")
					vim.cmd("edit!")
				else
					spinner.stop("error")
					local result = vim.fn.json_decode(stdout)
					print(vim.inspect(result))
				end
			end,
		}
	)
end

function M.retrieve(metadata_type, metadata_name)
	local spinner = require("sfwes.indicator")
	spinner.start()

	local stdout = ""
	local job = vim.fn.jobstart(
		_config.get("sf")
			.. string.format(" project retrieve start --json -m %s:%s --json", metadata_type, metadata_name),
		{
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
					print(vim.inspect(result))
				end
			end,
		}
	)
end

function M.create(component_type, component_name, file_path)
	file_path = file_path or "force-app/main/default/"
	local command = ""
	if component_type == "apex" then
		command = "apex generate class"
		file_path = file_path .. "classes"
	elseif component_type == "trigger" then
		command = "apex generate trigger"
		file_path = file_path .. "triggers"
	elseif component_type == "lwc" then
		command = "lightning generate component --type lwc"
		file_path = file_path .. "lwc"
	else
		-- TODO: throw error
	end

	local output = vim.fn.system(
		_config.get("sf") .. string.format(" %s --name %s --output-dir %s --json", command, component_name, file_path)
	)
	local result = vim.fn.json_decode(output)
	if result.status == 0 then
		vim.cmd("edit " .. result.result.created[1])
		M.deploy()
	else
		-- TODO: print error
	end
end

function M.run_test(test_class_name, test_name)
	print("Running single test")
	if vim.bo.ft == "apex" then
		vim.diagnostic.reset(_config.get_namespace(), 0)
		local spinner = require("sfwes.indicator")
		spinner.start()

		local stdout = ""
		local job = vim.fn.jobstart(
			_config.get("sf") .. string.format(" apex run test --tests %s.%s --json -w 20", test_class_name, test_name),
			{
				on_stdout = function(_, data)
					for _, line in ipairs(data) do
						stdout = stdout .. line .. "\n"
					end
				end,
				on_stderr = function(_, data, name) end,
				on_exit = function(_, data, exit_code)
					print(vim.inspect(data))
					if data == 0 then
						spinner.stop("success")
					elseif data == 100 then
						spinner.stop("error")
						local result = vim.fn.json_decode(stdout)
						local line_number = string.match(result.result.tests[1].StackTrace, "line (%d+)")
						local diagnostics = {}
						table.insert(diagnostics, {
							lnum = line_number - 1,
							col = -1,
							message = result.result.tests[1].Message,
							severity = vim.diagnostic.severity.ERROR,
							source = "sfwes",
						})
						vim.diagnostic.set(_config.get_namespace(), 0, diagnostics)
					else
						spinner.stop("error")
					end
				end,
			}
		)
	end
end

function M.run_tests(test_class_name)
	print("Running all tests")
	if vim.bo.ft == "apex" then
		vim.diagnostic.reset(_config.get_namespace(), 0)
		local spinner = require("sfwes.indicator")
		spinner.start()

		local stdout = ""
		local job = vim.fn.jobstart(
			_config.get("sf") .. string.format(" apex run test --tests %s --json -w 60", test_class_name),
			{
				on_stdout = function(_, data)
					for _, line in ipairs(data) do
						stdout = stdout .. line .. "\n"
					end
				end,
				on_stderr = function(_, data, name) end,
				on_exit = function(_, data, exit_code)
					print(vim.inspect(data))
					if data == 0 then
						spinner.stop("success")
					elseif data == 100 then
						spinner.stop("error")
						local result = vim.fn.json_decode(stdout)
						local diagnostics = {}
						for _, obj in ipairs(result.result.tests) do
							if obj.Outcome == "Fail" then
								local line_number = string.match(obj.StackTrace, "line (%d+)")
								table.insert(diagnostics, {
									lnum = line_number - 1,
									col = -1,
									message = obj.Message,
									severity = vim.diagnostic.severity.ERROR,
									source = "sfwes",
								})
							end
						end
						vim.diagnostic.set(_config.get_namespace(), 0, diagnostics)
					else
						spinner.stop("error")
					end
				end,
			}
		)
	end
end

return M
