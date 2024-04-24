local config = require("cmake.config")

local multiconfig_generators = {
	"Ninja Multi-Config",
	"Xcode",
	"Visual Studio 12 2013",
	"Visual Studio 14 2015",
	"Visual Studio 15 2017",
	"Visual Studio 16 2019",
	"Visual Studio 17 2022",
	"Green Hills MULTI",
}

local Capabilities = {
	json = nil,
}

function Capabilities.generators()
	local ret = {}
	if not Capabilities then
		return ret
	end
	for k, v in pairs(Capabilities.json.generators) do
		table.insert(ret, v.name)
	end
	return vim.fn.reverse(ret)
end

function Capabilities.is_multiconfig_generator(generator)
	-- if generator is nil, assume is is not multiconifg
	if not generator then
		return
	end
	return vim.tbl_contains(multiconfig_generators, generator)
end

function Capabilities.has_fileapi()
	return vim.tbl_get(Capabilities.json, "fileApi") ~= nil
end

-- TODO: make this async
Capabilities.setup = function(callback)
	local lines = {}
	vim.fn.jobstart({ config.cmake.cmake_path, "-E", "capabilities" }, {
		on_stdout = function(_, data)
			if data then
				vim.list_extend(lines, data)
			end
		end,
		on_exit = function(_, code, _)
			if code == 0 then
				Capabilities.json = vim.json.decode(table.concat(lines, ""))
				if type(callback) == "function" then
					callback()
				end
			else
				vim.notify("error " .. tostring(code) .. ". 'cmake -E capabilities'", vim.log.levels.ERROR)
			end
		end,
	})
end

return Capabilities
