local M = {}

local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local frame = 1
local status = "idle"
local timer = null

M.component = function()
	if status == "running" then
		return spinner_frames[frame]
	elseif status == "success" then
		return "✅"
	elseif status == "error" then
		return "❌"
	end
	return ""
end

M.start = function()
	if timer then
		return
	end
	status = "running"
	timer = vim.loop.new_timer()
	timer:start(
		0,
		50,
		vim.schedule_wrap(function()
			frame = (frame % #spinner_frames) + 1
			vim.cmd("redrawstatus")
		end)
	)
end

M.stop = function(newStatus)
	if timer then
		timer:stop()
		timer:close()
		timer = nil
	end
	status = newStatus
	vim.cmd("redrawstatus")
	vim.defer_fn(function()
		status = "idle"
		vim.cmd("redrawstatus")
	end, 2000)
end

return M
