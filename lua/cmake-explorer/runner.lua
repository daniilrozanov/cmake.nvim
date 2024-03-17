local Job = require("plenary.job")

local M = {}

local running_jobs = {}
local last_job = nil

function M.start(command)
	if not command then
		print("runner start. command is nil")
		return
	end
	local env = vim.tbl_extend("force", vim.loop.os_environ(), command.env and command.env or {})

	vim.notify(command.cmd .. " " .. table.concat(command.args, " "))
	local job = Job:new({
		command = command.cmd,
		args = command.args,
		env = env,
		on_exit = vim.schedule_wrap(function(_, code, signal)
			if code == 0 and signal == 0 and command.after_success then
				command.after_success()
			else
				vim.notify(
					"Code " .. tostring(code) .. ": " .. command.cmd .. " " .. table.concat(command.args, " "),
					vim.log.levels.ERROR
				)
			end
		end),
	})
	job:start()
	table.insert(running_jobs, job)
	last_job = job
end

function M.cancel_job()
	if not last_job then
		return false
	end

	-- Check if this job was run through debugger.
	if last_job.session then
		if not last_job.session() then
			return false
		end
		last_job.terminate()
		return true
	end

	if last_job.is_shutdown then
		return false
	end

	last_job:shutdown(1, 9)

	if vim.fn.has("win32") == 1 or vim.fn.has("mac") == 1 then
		-- Kill all children.
		for _, pid in ipairs(vim.api.nvim_get_proc_children(last_job.pid)) do
			vim.loop.kill(pid, 9)
		end
	else
		vim.loop.kill(last_job.pid, 9)
	end
	return true
end

return M
