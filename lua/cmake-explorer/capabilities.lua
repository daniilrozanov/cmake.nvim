local config = require("cmake-explorer.config")

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

Capabilities.setup = function()
	local output = vim.fn.system({ config.cmake_path, "-E", "capabilities" })
	Capabilities.json = vim.json.decode(output)
end

return Capabilities
