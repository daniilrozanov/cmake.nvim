local default_config = {
	cmake = {
		cmake_path = "cmake",
		ctest_path = "ctest",
		cpack_path = "cpack",
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
		parallel_jobs = nil,
	},
	save_before_build = true,
	generate_after_save = true,
	cmake_terminal = {
		split = "below",
		size = 15,
		close_on_exit = "success",
		open_on_start = true,
		clear_env = false,
		enter = false,
	},
	target_terminal = {
		split = "below",
		size = 15,
		clear_env = false,
		enter = true,
	},
	notification = {
		after = "success",
	},
	variants_display = {
		short = { sep = " × ", show = true },
		long = { sep = " ❄ ", show = false },
	},
	keybinds = {},
}

local M = vim.deepcopy(default_config)

M.setup = function(opts)
	local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

	for k, v in pairs(newconf) do
		M[k] = v
	end
end

return M
