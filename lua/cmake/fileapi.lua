local capabilities = require("cmake.capabilities")
local Path = require("plenary.path")
local scan = require("plenary.scandir")
local utils = require("cmake.utils")
local uv = vim.loop

local query_path_suffix = { ".cmake", "api", "v1", "query", "client-cmake", "query.json" }
local reply_dir_suffix = { ".cmake", "api", "v1", "reply" }

local FileApi = {}

function FileApi.create(path, callback)
	local query = Path:new(path, unpack(query_path_suffix)):normalize()
	utils.file_exists(query, function(exists)
		if not exists then
			if capabilities.json.fileApi then
				vim.schedule(function()
					--TODO: change to async
					vim.fn.mkdir(Path:new(vim.fs.dirname(query)):absolute(), "p")
					utils.write_file(query, vim.json.encode(capabilities.json.fileApi), callback)
				end)
			else
				vim.notify("Bad fileApi ", vim.log.levels.ERROR)
			end
		else
			callback()
		end
	end)
end

function FileApi.read_reply(path, callback)
	local reply_dir = Path:new(path, unpack(reply_dir_suffix)):absolute()
	utils.file_exists(reply_dir, function(exists)
		if not exists then
			return
		end
		local ret = { targets = {} }
		scan.scan_dir_async(reply_dir, {
			search_pattern = "index*",
			on_exit = function(results)
				if #results == 0 then
					return
				end
				utils.read_file(results[1], function(index_data)
					local index = vim.json.decode(index_data)
					for _, object in ipairs(index.objects) do
						if object.kind == "codemodel" then
							utils.read_file(Path:new(reply_dir, object.jsonFile):absolute(), function(codemodel_data)
								local codemodel = vim.json.decode(codemodel_data)
								--FIX: this loop does not read all files if codemodel contains many targets. This is because libuv (or some external settings) forbids to open files
								-- in async mode more than some limit number. Seems like the solution is to queue these calls and limit max number for opened files per time
								for _, target in ipairs(codemodel.configurations[1].targets) do
									utils.read_file(
										Path:new(reply_dir, target.jsonFile):absolute(),
										function(target_data)
											local target_json = vim.json.decode(target_data)
											local _target = {
												id = target_json.id,
												name = target_json.name,
												type = target_json.type,
											}
											if target_json.artifacts then
												--NOTE: add_library(<name> OBJECT ...) could contain more than ohe object in artifacts
												-- so maybe in future it will be useful to handle not only first one. Current behaviour
												-- aims to get path for only EXECUTABLE targets
												_target.path = target_json.artifacts[1].path
											end
											callback(_target)
										end
									)
								end
							end)
						end
					end
				end)
			end,
		})
		return ret
	end)
end

function FileApi.query_exists(path, callback)
	utils.file_exists(Path:new(path, unpack(query_path_suffix)):normalize(), function(query_exists)
		callback(query_exists)
	end)
end

function FileApi.exists(path, callback)
	FileApi.query_exists(path, function(query_exists)
		if not query_exists then
			callback(false)
		else
			utils.file_exists(Path:new(path, unpack(reply_dir_suffix)):normalize(), function(reply_exists)
				callback(reply_exists)
			end)
		end
	end)
end

return FileApi
