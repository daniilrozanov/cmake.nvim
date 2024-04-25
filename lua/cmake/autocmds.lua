local config = require("cmake.config")
local actions = require("cmake.actions")
local constants = require("cmake.constants")

local autocmds = {}

function autocmds.setup()
	local cmake_nvim_augroup = vim.api.nvim_create_augroup("CMake", {})
	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		group = cmake_nvim_augroup,
		pattern = constants.variants_yaml_filename,
		callback = function(args)
			require("cmake.project").setup()
		end,
		desc = "Setup project after saving variants",
	})
	if config.generate_after_save then
		vim.api.nvim_create_autocmd({ "BufWritePost" }, {
			group = cmake_nvim_augroup,
			pattern = constants.cmakelists,
			callback = function(args)
				actions.generate()
			end,
			desc = "Generate project after saving CMakeLists.txt",
		})
	end
end

return autocmds
