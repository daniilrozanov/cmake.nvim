local config = require("cmake-explorer.config")
local capabilities = require("cmake-explorer.capabilities")
local FileApi = require("cmake-explorer.file_api")
local Path = require("plenary.path")
local Scandir = require("plenary.scandir")
local utils = require("cmake-explorer.utils")
local notif = require("cmake-explorer.notification")

local Project = {}

Project.__index = Project

function Project:new(o)
	o = o or {}

	local path
	if type(o) == "string" then
		path = o
	elseif type(o) == "table" and o.path then
		path = o.path
	else
		return
	end

	if not Path:new(path, "CMakeLists.txt"):exists() then
		return
	end

	local obj = {
		path = path,
		fileapis = {},
		last_generate = nil,
	}
	notif.notify("PATH " .. obj.path)
	setmetatable(
		obj.fileapis,
		utils.make_maplike_list(function(v)
			return v.path
		end)
	)
	setmetatable(obj, Project)
	return obj
end

function Project:scan_build_dirs()
	local builds_root = utils.is_eq(
		Path:new(config.build_dir):is_absolute(),
		true,
		Path:new(config.build_dir),
		Path:new(self.path, config.build_dir)
	)
	local candidates =
			Scandir.scan_dir(builds_root:absolute(), { hidden = false, only_dirs = true, depth = 0, silent = true })
	for _, v in ipairs(candidates) do
		local fa = FileApi:new(v)
		if fa and fa:exists() and fa:read_reply() then
			self.fileapis[fa.path] = fa
		end
	end
end

function Project:symlink_compile_commands(path)
	local src = Path:new(path, "compile_commands.json")
	if src:exists() then
		vim.cmd(
			'silent exec "!'
			.. config.cmake_cmd
			.. " -E create_symlink "
			.. src:normalize()
			.. " "
			.. Path:new(self.path, "compile_commands.json"):normalize()
			.. '"'
		)
	end
end

function Project:configure(params)
	params = params or {}
	local args = utils.generate_args(params, self.path)
	local build_dir = utils.build_path(params, self.path)
	if not args then
		return
	end
	if not self.fileapis[build_dir] then
		local fa = FileApi:new(build_dir)
		if not fa then
			notif.notify("Cannot fileapi object", vim.log.levels.ERROR)
			return
		end
		if not fa:create() then
			return
		end
		self.fileapis[build_dir] = fa
	end

	local job_args = {
		cmd = config.cmake_cmd,
		args = args,
		cwd = self.path,
		after_success = function()
			self.last_generate = job_args
			self.fileapis[build_dir]:read_reply()
			self:symlink_compile_commands(build_dir)
		end,
	}
	return job_args
end

function Project:configure_last()
	return self.last_generate
end

return Project
