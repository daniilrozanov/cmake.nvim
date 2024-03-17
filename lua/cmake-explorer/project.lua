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
		path = Path:new(path):absolute(),
		fileapis = {},
		last_generate = {},
	}
	setmetatable(obj, Project)
	return obj
end

function Project:scan_build_dirs()
	local candidates = Scandir.scan_dir(self.path, { hidden = false, only_dirs = true, depth = 0, silent = true })
	for _, v in ipairs(candidates) do
		local fa = FileApi:new(v)
		if fa and fa:exists() and fa:read_reply() then
			self.fileapis[v] = fa
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
			.. src:absolute()
			.. " "
			.. Path:new(self.path, "compile_commands.json"):absolute()
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

	return {
		cmd = config.cmake_cmd,
		args = args,
		cwd = Path:new(self.path):absolute(),
		after_success = function()
			self.last_generate = build_dir
			self.fileapis[build_dir]:read_reply()
			self:symlink_compile_commands(build_dir)
		end,
	}
end

function Project:configure_last()
	return self:configure(self.last_generate)
end

function Project:list_build_dirs()
	local ret = {}
	for k, _ in pairs(self.fileapis) do
		local build = {}
		build.path = k
		table.insert(ret, build)
	end
	return ret
end

return Project
