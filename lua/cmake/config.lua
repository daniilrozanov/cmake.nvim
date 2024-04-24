local default_config = {
	cmake = {
		cmake_path = "cmake",
		environment = {},
		configure_environment = {},
		build_directory = "${workspaceFolder}/build-${buildType}",
		build_environment = {},
		build_args = {},
		build_tool_args = {},
		generator = nil,
		variants = {
			{
				default = "debug",
				description = "Build type",
				choices = {
					debug = { short = "Debug", long = "Long debug", buildType = "Debug" },
					release = { short = "Release", long = "Long release", buildType = "Release" },
				},
			},
			{
				default = "static",
				choices = {
					static = { short = "Static", long = "Long static", linkage = "static" },
					shared = { short = "Shared", long = "Long shared", linkage = "shared" },
				},
			},
		},
		parallel_jobs = 0,
		save_before_build = true,
		source_directory = "${workspaceFolder}",
	},
	terminal = {
		direction = "horizontal",
		display_name = "CMake",
		close_on_exit = "success",
		hidden = false,
		clear_env = false,
		focus = false,
	},
	runner_terminal = {
		direction = "horizontal",
		close_on_exit = false,
		hidden = false,
		clear_env = false,
		focus = true,
	},
	notification = {
		after = "success",
	},
	variants_display = {
		short = { sep = " × " },
		long = { sep = " ❄ " },
	},
}

local M = vim.deepcopy(default_config)

M.setup = function(opts)
	local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

	for k, v in pairs(newconf) do
		M[k] = v
	end
end

return M
