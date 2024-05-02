---@class CMakeConfig
---@field cmake CMakeConfigCMake Configuration for `cmake` command itself
---@field save_before_build boolean Save all unsaved files before running `cmake`
---@field generate_after_save boolean Generate after saving `CMakeLists.txt` file
---@field cmake_terminal CMakeConfigCMakeTerminal Settings for terminal where cmake will be executed
---@field target_terminal CMakeConfigTargetTerminal Settings for terminal where executable targets will be executed
---@field disabled_commands string[] List of commands that will not be initialized

---@class CMakeConfigCMake
---@field cmake_path string Path to `cmake` executable
---@field ctest_path string Path to `ctest` executable
---@field cpack_path string Path to `cpack` executable
---@field build_args string[] An array of additional arguments to pass to `cmake --build`
---@field build_tool_args string[] An array of additional arguments to pass to the underlying build tool
---@field generator? string Set to a string to override CMake Tools’ preferred generator logic. If this is set, CMake will unconditionally use it as the -G CMake generator command line argument
---@field parallel_jobs? number By specifying a number, you can define how many jobs are run in parallel during the build
---@field variants {[string]:CMakeVariant} Default variants. Parameters defined in variants have more priority than defined in `cmake = {...}` ones

---@class CMakeVariant
---@field default string Default choice
---@field description string Description for variant option
---@field choices {[string]:CMakeVariantChoice} Choices for variant option

---@class CMakeVariantChoice
---@field short string Short description for choice
---@field long? string Short description for choice
---@field buildType? string Value for `CMAKE_BUILD_TYPE` variable.
---@field generator? string Set to a string to override CMake Tools’ preferred generator logic. If this is set, CMake will unconditionally use it as the -G CMake generator command line argument
---@field buildArgs? string[] An array of additional arguments to pass to `cmake --build`
---@field buildToolArgs? string[] An array of additional arguments to pass to the underlying build tool
---@field settings? {[string]:string} Table of parameters which will be passed as `-Dkey=value` to `cmake` command
---@field env? {[string]:string} Table of parameters which will be passed as environment variables to `cmake`
---@field linkage? "static"|"shared" Linkage type

---@class CMakeConfigCMakeTerminal
---@field split "left"|"right"|"below"|"above" Split direction
---@field size number Terminal's size in lines
---@field close_on_exit "success"|"failure"|boolean When to close termilal. `"success"` - after success, `"failure"` - after failure, `true` - always, `false` - never
---@field open_on_start boolean Open terminal when `cmake` starts
---@field clear_env boolean Do not pass shell environment to cmake process
---@field enter boolean Focus on opened terminal window

---@class CMakeConfigTargetTerminal
---@field split "left"|"right"|"below"|"above" Split direction
---@field size number Terminal's size in lines
---@field enter boolean Focus on opened terminal window
---@field immediately boolean Run command immediately. If false, command will just be pasted to terminal so you can modify it

---@type CMakeConfig
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
		enter = true,
		immediately = true,
	},
	notification = {
		after = "success",
	},
	variants_display = {
		short = { sep = " × ", show = true },
		long = { sep = " ❄ ", show = false },
	},
	keybinds = {},
	disable_commands = {},
}

local M = vim.deepcopy(default_config)

---Setup configs
---@param opts CMakeConfig
M.setup = function(opts)
	local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

	for k, v in pairs(newconf) do
		M[k] = v
	end
end

return M
