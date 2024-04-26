local config = require("cmake.config")
local actions = require("cmake.actions")
local constants = require("cmake.constants")

local autocmds = {}

local cmake_nvim_augroup = vim.api.nvim_create_augroup("CMake", {})

function autocmds.set_on_variants()
	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		group = cmake_nvim_augroup,
		pattern = constants.variants_yaml_filename,
		callback = function(args)
			actions.reset_project()
		end,
		desc = "Setup project after saving variants",
	})
end

function autocmds.setup()
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
	--NOTE: this autocmd was written only to handle very rarely case when inside directory
	--without CMakeLists.txt neovim starts like `nvim CMakeLists.txt`. In this case initial
	--setup will not make the affect and to correctry process the file save, we need to create
	--this autocommand so it reinitializes the project if it has not been done before. IMHO this
	--is not the best way to do this
	if config.generate_after_save then
		vim.api.nvim_create_autocmd({ "BufEnter" }, {
			group = cmake_nvim_augroup,
			pattern = constants.cmakelists,
			callback = function(args)
				actions.reset_project({ first_time_only = true })
			end,
			desc = "Set up project on open CMakeLists.txt if not set before",
		})
	end
end

return autocmds
