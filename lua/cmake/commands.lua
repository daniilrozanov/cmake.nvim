local M = {}

local cmd = vim.api.nvim_create_user_command

M.register_commands = function()
	cmd("CMakeGenerate", function()
		require("cmake.actions").generate()
	end, { desc = "Generate with last configuration" })

	cmd("CMakeGenerateSelect", function()
		require("cmake.actions").generate_select()
	end, { desc = "Select configuration and generate" })

	cmd("CMakeBuild", function()
		require("cmake.actions").build()
	end, { desc = "Build with last build option" })

	cmd("CMakeBuildSelect", function()
		require("cmake.actions").build_select()
	end, { desc = "Select build option and build" })

	cmd("CMakeRun", function()
		require("cmake.actions").run_tagret()
	end, { desc = "Select build option and build" })

	cmd("CMakeRunSelect", function()
		require("cmake.actions").run_tagret_select()
	end, { desc = "Select build option and build" })

	cmd("CMakeToggle", function()
		require("cmake.actions").toggle()
	end, { desc = "Toggle CMake terminal" })
end

return M
