local config = require("cmake-explorer.config")
local runner = require("cmake-explorer.runner")
local Project = require("cmake-explorer.project")
local capabilities = require("cmake-explorer.capabilities")
local utils = require("cmake-explorer.utils")
local Path = require("plenary.path")

local M = {}

local project = nil

local format_build_dir = function()
	if Path:new(config.build_dir):is_absolute() then
		return function(v)
			return Path:new(v.path):make_relative(vim.env.HOME)
		end
	else
		return function(v)
			return Path:new(v.path):make_relative(project.path)
		end
	end
end

function M.list_build_dirs()
	if project then
		vim.print(project:list_build_dirs())
	end
end

function M.configure()
	assert(project)
	local generators = capabilities.generators()
	table.insert(generators, 1, "Default")
	vim.ui.select(generators, { prompt = "Select generator" }, function(generator)
		if not generator then
			return
		end
		-- TODO: handle default generator from env (or from anywhere else)
		generator = utils.is_neq(generator, "Default")
		vim.ui.select(config.build_types, { prompt = "Select build type" }, function(build_type)
			if not build_type then
				return
			end
			vim.ui.input({ prompt = "Input additional args" }, function(args)
				if not build_type then
					return
				end
				local task = project:configure({ generator = generator, build_type = build_type, args = args })
				runner.start(task)
			end)
		end)
	end)
end

function M.configure_dir()
	assert(project)

	vim.ui.select(
		project:list_build_dirs(),
		{ prompt = "Select directory to build", format_item = format_build_dir() },
		function(dir)
			if not dir then
				return
			end
			local task = project:configure(dir.path)
			runner.start(task)
		end
	)
end

function M.configure_last()
	local task = project:configure_last()
	runner.start(task)
end

M.setup = function(cfg)
	cfg = cfg or {}

	config.setup(cfg)
	capabilities.setup()

	project = Project:new(vim.loop.cwd())
	if not project then
		print("cmake-explorer: no CMakeLists.txt file found. Aborting setup")
		return
	end
	project:scan_build_dirs()

	local cmd = vim.api.nvim_create_user_command

	cmd("CMakeConfigure", M.configure, { -- opts
		nargs = 0,
		bang = true,
		desc = "CMake configure with parameters",
	})

	cmd(
		"CMakeConfigureLast",
		M.configure_last,
		{ nargs = 0, bang = true, desc = "CMake configure last if exists. Otherwise default" }
	)

	cmd(
		"CMakeConfigureDir",
		M.configure_dir,
		{ nargs = 0, bang = true, desc = "CMake configure last if exists. Otherwise default" }
	)

	cmd("CMakeListBuilds", M.list_build_dirs, { nargs = 0 })
end

return M
