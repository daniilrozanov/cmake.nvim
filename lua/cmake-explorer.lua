local globals = require("cmake-explorer.globals")
local config = require("cmake-explorer.config")
local runner = require("cmake-explorer.runner")
local Project = require("cmake-explorer.project")
local Build = require("cmake-explorer.build")

local M = {}

local projects = {}

local current_project = nil

local function set_current_project(path)
	if path then
		for _, v in ipairs(projects) do
			-- print(v.path:absolute() .. " ? " .. path)
			if v.path:absolute() == path then
				current_project = v
				return
			end
		end
	end
	if #projects ~= 0 then
		current_project = projects[1]
	else
		print("set_current_project. no projects available")
	end
end

function M.list_build_dirs()
	if current_project then
		vim.print(current_project:list_build_dirs_names())
	end
end

function M.configure(opts)
	print("configure. #projects " .. #projects)
	if current_project then
		runner.start(current_project:configure(opts))
	end
end

M.setup = function(cfg)
	cfg = cfg or {}
	globals.setup()
	config.setup(cfg)

	projects = { Project:new(vim.loop.cwd()) }
	set_current_project()

	local cmd = vim.api.nvim_create_user_command

	cmd("CMakeConfigure", function(opts)
		if #opts.fargs ~= 0 then
			M.configure({ build_type = opts.fargs[1] })
		else
			M.configure()
		end
	end, { -- opts
		nargs = "*",
		bang = true,
		desc = "CMake configure",
	})

	cmd("CMakeListBuildDirs", M.list_build_dirs, { nargs = 0 })
end

return M
