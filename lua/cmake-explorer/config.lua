local default_config = {
	cmake_cmd = "cmake",
	build_dir_template = "build-{buildType}",
	build_types = { "Debug", "Release" },
	options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" },
}

local M = vim.deepcopy(default_config)

M.setup = function(opts)
	local newconf = vim.tbl_deep_extend("force", default_config, opts or {})

	for k, v in pairs(newconf) do
		M[k] = v
	end
end

return M
