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
			buildType = {
				default = "debug",
				description = "Build type",
				choices = {
					debug = { short = "Debug", buildType = "Debug" },
					release = { short = "Release", buildType = "Release" },
					relWithDebInfo = { short = "Release with debug info", buildType = "RelWithDebInfo" },
					minSizeRel = { short = "Minimal size releaze", buildType = "MinSizeRel" },
				},
			},
		},
		parallel_jobs = 0,
		save_before_build = true,
		source_directory = "${workspaceFolder}",
	},
	terminal = {
		direction = "vertical",
		display_name = "CMake",
		close_on_exit = "success",
		hidden = false,
		clear_env = false,
		focus = false,
	},
	runner_terminal = {
		direction = "vertical",
		close_on_exit = false,
		hidden = false,
		clear_env = false,
		focus = false,
	},
	notification = {
		after = "success",
	},
	variants_display = {
		short = { sep = " × ", show = true },
		long = { sep = " ❄ ", show = false },
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
