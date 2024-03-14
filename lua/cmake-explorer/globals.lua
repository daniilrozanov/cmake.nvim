local config = require("cmake-explorer.config")

local M = {
	capabilities = nil,
	generators = {},
}

local available_generators = function(capabilities)
	local ret = {}
	if not capabilities or not capabilities.generators then
		return ret
	end
	for k, v in pairs(capabilities.generators) do
		table.insert(ret, v.name)
	end
	return vim.fn.reverse(ret)
end

local set_capabilities = function()
	local output = vim.fn.system({ config.cmake_cmd, "-E", "capabilities" })
	M.capabilities = vim.json.decode(output)
	M.generators = available_generators(M.capabilities)
end

M.setup = function()
	set_capabilities()
end

return M
