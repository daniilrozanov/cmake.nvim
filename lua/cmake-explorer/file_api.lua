local capabilities = require("cmake-explorer.capabilities")
local Path = require("plenary.path")
local Scandir = require("plenary.scandir")
local notif = require("cmake-explorer.notification")
local utils = require("cmake-explorer.utils")

local query_path_suffix = { ".cmake", "api", "v1", "query", "client-cmake-explorer", "query.json" }
local reply_dir_suffix = { ".cmake", "api", "v1", "reply" }

local FileApi = {}

FileApi.__index = FileApi

function FileApi:new(opts)
	if not capabilities.has_fileapi() then
		notif.notify("No fileapi files", vim.log.levels.ERROR)
		return
	end
	local path
	if type(opts) == "string" then
		path = opts
	end
	local obj = {
		path = path,
		index = nil,
		cmakefiles = nil,
		codemodel = nil,
		targets = {},
	}
	setmetatable(obj, FileApi)
	return obj
end

function FileApi:create()
	local query = Path:new(self.path, unpack(query_path_suffix))
	if not query:exists() then
		if not query:touch({ parents = true }) then
			notif.notify("Cannot create query file", vim.log.levels.ERROR)
			return
		end
		query:write(vim.json.encode(capabilities.json.fileApi), "w")
	end
	Path:new(self.path, unpack(reply_dir_suffix)):mkdir({ parents = true })
	return true
end

function FileApi:read_reply()
	if not self:reply_exists() then
		notif.notify("No reply directory", vim.log.levels.ERROR)
		return
	end
	local reply_dir = Path:new(self.path, unpack(reply_dir_suffix))
	local index = Scandir.scan_dir(tostring(reply_dir), { search_pattern = "index*" })
	if #index == 0 then
		notif.notify("No files in reply", vim.log.levels.ERROR)
		return
	end
	self.index = vim.json.decode(Path:new(index[1]):read())
	for _, object in ipairs(self.index.objects) do
		if object.kind == "codemodel" then
			self.codemodel = vim.json.decode((reply_dir / object.jsonFile):read())
			for _, target in ipairs(self.codemodel.configurations[1].targets) do
				self.targets[target.name] = vim.json.decode((reply_dir / target.jsonFile):read())
			end
		elseif object.kind == "cmakeFiles" then
			self.cmakefiles = vim.json.decode(Path:new(reply_dir / object.jsonFile):read())
		end
	end
	return true
end

function FileApi:query_exists()
	return Path:new(self.path, unpack(query_path_suffix)):exists()
end

function FileApi:reply_exists()
	local reply_dir = Path:new(self.path, unpack(reply_dir_suffix))
	if not reply_dir:exists() then
		return
	end
	return true
end

function FileApi:exists()
	return self:query_exists() and self:reply_exists()
end

function FileApi.is_fileapi(other)
	return getmetatable(other) == FileApi
end

return FileApi
