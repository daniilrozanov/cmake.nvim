local config = require("cmake-explorer.config")
local globals = require("cmake-explorer.globals")
local Build = require("cmake-explorer.build")
local Path = require("plenary.path")
local Scandir = require("plenary.scandir")
local utils = require("cmake-explorer.utils")

local get_builds_in_dir = function(path)
	local ret = {}
	-- add to builds directories which accept is_build_dir()
	local candidates = Scandir.scan_dir(path, { hidden = false, only_dirs = true, depth = 0, silent = true })
	for _, v in ipairs(candidates) do
		if Build.is_build_dir(v) then
			local b = Build:new(v)
			table.insert(ret, b)
		end
	end
	return ret
end

local set_current_build = function(builds, filter)
	local filter_func
	if type(filter) == "number" then
		if filter >= 1 and filter <= #builds then
			return builds[filter]
		else
			print("set_current_build. index out of range. set to first")
			return builds[1]
		end
	elseif type(filter) == "string" then
		filter_func = function(v)
			return v:build_type() == filter
		end
	elseif type(filter) == "function" then
		filter_func = filter
	else
		return builds[1]
	end
	for _, v in ipairs(builds) do
		if filter_func(v) == true then
			return v
		end
	end
	return builds[1]
end

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
		path = Path:new(path),
		builds = nil,
		current_build = nil,
	}
	obj.builds = get_builds_in_dir(path)
	obj.current_build = set_current_build(obj.builds, config.build_types[1])
	setmetatable(obj, Project)
	return obj
end

-- finds build with passed params, creates new build if not found
function Project:append_build(params)
	local build_dir = (self.path / Build.name(params)):absolute()
	for _, v in ipairs(self.builds) do
		if v.path:absolute() == build_dir then
			print("append_build. build found")
			return v
		end
	end
	print("append_build. new build")
	table.insert(self.builds, Build:new(build_dir))
	return self.builds[#self.builds]
end

function Project:symlink_compile_commands()
	local src = (self.current_build.path / "compile_commands.json")
	if src:exists() then
		vim.cmd(
			'silent exec "!'
				.. config.cmake_cmd
				.. " -E create_symlink "
				.. src:absolute()
				.. " "
				.. (self.path / "compile_commands.json"):absolute()
				.. '"'
		)
	end
end

function Project:list_build_dirs_names()
	local ret = {}
	for _, v in ipairs(self.builds) do
		table.insert(ret, v.path:absolute())
	end
	return ret
end

function Project:configure(params)
	params = params or {}

	self.current_build = self:append_build(params)
	local args = vim.tbl_deep_extend("keep", params.args or {}, config.options or {})
	table.insert(args, "-G" .. (params.generator or globals.generators[1]))
	table.insert(args, "-DCMAKE_BUILD_TYPE=" .. (params.build_type or config.build_types[1]))
	table.insert(args, "-S" .. self.path:absolute())
	table.insert(args, "-B" .. self.current_build.path:absolute())
	return {
		cmd = config.cmake_cmd,
		args = args,
		after_success = function()
			self:symlink_compile_commands()
		end,
	}
end

return Project
