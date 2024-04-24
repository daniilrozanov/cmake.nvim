local config = require("cmake.config")
local commands = require("cmake.commands")

local M = {}

function M.setup(opts)
	opts = opts or {}
	config.setup(opts)
	if vim.fn.executable(config.cmake.cmake_path) then
		commands.register_commands()
		require("cmake.capabilities").setup(function()
			require("cmake.project").setup(opts)
		end)
	else
		vim.notify("CMake: " .. config.cmake.cmake_path .. " is not executable", vim.log.levels.WARN)
	end
end

return M
