local Terminal = require("toggleterm.terminal").Terminal
local ui = require("toggleterm.ui")
local config = require("cmake.config")

local M = {}

local cmake
local runnable

--TODO: cmake must be an id, not terminal

M.cmake_execute = function(command, opts)
	opts = opts or {}
	if cmake then
		cmake:shutdown()
		cmake = nil
	end
	local term_opts = {
		direction = config.terminal.direction,
		display_name = config.terminal.display_name,
		hidden = config.terminal.hidden,
		clear_env = config.terminal.clear_env,
		cmd = command.cmd .. " " .. command.args,
		-- env = command.env,
		on_exit = function(t, pid, code, name)
			if code == 0 then
				command.after_success()
				if config.terminal.close_on_exit == "success" then
					t:close()
				end
				if config.notification.after == "success" or config.notification.after == true then
					vim.notify(
						vim.tbl_get(opts, "notify", "ok_message") or "CMake successfully completed",
						vim.log.levels.INFO
					)
				end
			elseif config.notification.after == "failure" or config.notification.after == true then
				vim.notify(vim.inspect("failure "))
				local msg = "CMake failed. Code " .. tostring(code)
				local opt_msg = vim.tbl_get(opts, "notify", "err_message")
				if type(opt_msg) == "string" then
					msg = opt_msg
				elseif type(opt_msg) == "function" then
					msg = opt_msg(code)
				end
				vim.notify(msg, vim.log.levels.ERROR)
			end
		end,
		on_open = function(t)
			t:set_mode("n")
		end,
	}
	term_opts.close_on_exit = type(config.terminal.close_on_exit) == "boolean" and config.terminal.close_on_exit
		or false
	cmake = Terminal:new(term_opts)
	cmake:open()
	if not config.terminal.focus and cmake:is_focused() then
		ui.goto_previous()
		ui.stopinsert()
	end
end

M.cmake_toggle = function()
	if cmake then
		cmake:toggle()
	else
		vim.notify("No CMake terminal")
	end
end

M.target_execute = function(command, opts)
	opts = opts or {}
	local term_opts = {
		direction = config.runner_terminal.direction,
		close_on_exit = config.runner_terminal.close_on_exit,
		hidden = config.runner_terminal.hidden,
		clear_env = config.clear_env,
	}
	if not runnable then
		runnable = Terminal:new(term_opts)
	end
	if not runnable:is_open() then
		runnable:open()
	end
	vim.notify(vim.inspect(command), vim.log.levels.INFO)
	if command.cmd then
		runnable:send(command.cmd, not config.runner_terminal.focus)
	end
end

return M
