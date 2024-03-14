local config = require("cmake-explorer.config")
local Path = require("plenary.path")
local Scandir = require("plenary.scandir")

-- initial action to create query files (before first build)
local init_query_dir = function(path)
	Path:new(path, ".cmake", "api", "v1", "query", "codemodel-v2"):touch({ parents = true })
	Path:new(path, ".cmake", "api", "v1", "query", "cmakeFiles-v1"):touch({ parents = true })
	Path:new(path, ".cmake", "api", "v1", "reply"):mkdir({ parents = true })
end

local read_reply_dir = function(path)
	local index, cmakefiles, codemodel, targets
	local reply_dir = Path:new(path, ".cmake", "api", "v1", "reply")
	if not reply_dir:exists() then
		return
	end
	index = Scandir.scan_dir(reply_dir:absolute(), { search_pattern = "index*" })
	if #index == 0 then
		return
	end
	index = vim.json.decode(Path:new(index[1]):read())
	for _, object in ipairs(index.objects) do
		if object.kind == "codemodel" then
			codemodel = vim.json.decode((reply_dir / object.jsonFile):read())
			for _, target in ipairs(codemodel.configurations[1].targets) do
				targets = targets or {}
				table.insert(targets, vim.json.decode((reply_dir / target.jsonFile):read()))
			end
		elseif object.kind == "cmakeFiles" then
			cmakefiles = vim.json.decode(Path:new(reply_dir / object.jsonFile):read())
		end
	end
	return index, cmakefiles, codemodel, targets
end

local Build = {}

Build.__index = Build

-- new buildsystem
function Build:new(o)
	o = o or {}

	local path
	if type(o) == "string" then
		path = o
	elseif type(o) == "table" and o.path then
		path = o.path
	else
		print("Build.new wrong argument. type(o) = " .. type(o))
		return
	end

	local obj = {
		path = Path:new(path),
		index = nil,
		cmakefiles = nil,
		codemodel = nil,
		targets = nil,
	}

	obj.path:mkdir({ parents = true })
	init_query_dir(path)
	obj.index, obj.cmakefiles, obj.codemodel, obj.targets = read_reply_dir(path)

	setmetatable(obj, Build)
	return obj
end

-- update all internals
function Build:update()
	self:set_codemodel()
	self:set_cmakefiles()
end

function Build:build() end

function Build:generator()
	return self.index.cmake.generator.name
end

function Build:build_type()
	return self.codemodel.configurations[1].name
end

function Build:is_multiconfig()
	return self.index.cmake.generator.multiConfig
end

Build.name = function(opts)
	return config.build_dir_template:gsub("{buildType}", opts.build_type or config.build_types[1])
end

Build.is_build_dir = function(path)
	if not (Path:new(path):is_dir()) then
		return
	end
	if not Path:new(path, ".cmake", "api", "v1", "query", "codemodel-v2"):exists() then
		return
	elseif not Path:new(path, ".cmake", "api", "v1", "query", "cmakeFiles-v1"):exists() then
		return
	end
	return true
end

return Build
