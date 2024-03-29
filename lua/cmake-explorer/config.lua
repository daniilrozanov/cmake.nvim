local default_config = {
	cmake_path = "cmake",
	environment = {},
	configure_environment = {},
	build_directory = "${workspaceFolder}/build-${buildType}",
	build_environment = {},
	build_args = {},
	build_tool_args = {},
	generator = nil,
	default_variants = {
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
	variants_display = {
		short_sep = " × ",
		long_sep = " ❄ ",
	},
	parallel_jobs = nil,
	save_before_build = true,
	source_directory = "${workspaceFolder}",
}

local M = vim.deepcopy(default_config)

M.setup = function(opts)
	local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

	for k, v in pairs(newconf) do
		M[k] = v
	end
end

return M
