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
		parallel_jobs = nil, --#(vim.uv or vim.loop).cpu_info(),
		-- source_directory = "${workspaceFolder}", --TODO: not used
	},
	save_before_build = true,
	generate_after_save = true,
	terminal = {
		direction = "horizontal",
		display_name = "CMake", --TODO: not used
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
