local config = require("cmake.config")
local utils = require("cmake.utils")

local uv = vim.uv

local VariantConfig = {}

VariantConfig.__index = VariantConfig

local global_variant_subs = {
	["${workspaceFolder}"] = uv.cwd(),
	["${userHome}"] = uv.os_homedir(),
}

local _configure_args = function(obj, build_directory)
	local args = {}
	if obj.generator then
		table.insert(args, "-G " .. '"' .. obj.generator .. '"')
	end
	table.insert(args, "-B" .. build_directory)
	if obj.buildType then
		table.insert(args, "-DCMAKE_BUILD_TYPE=" .. obj.buildType)
	end
	if obj.linkage and string.lower(obj.linkage) == "static" then
		table.insert(args, "-DCMAKE_BUILD_SHARED_LIBS=OFF")
	elseif obj.linkage and string.lower(obj.linkage) == "shared" then
		table.insert(args, "-DCMAKE_BUILD_SHARED_LIBS=ON")
	end
	for k, v in pairs(obj.settings or {}) do
		table.insert(args, "-D" .. k .. "=" .. v)
	end
	table.insert(args, "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON")
	return args
end

local _configure_command = function(obj, configure_args)
	local ret = {}
	ret.cmd = config.cmake.cmake_path
	ret.args = table.concat(configure_args, " ")
	ret.env = vim.tbl_deep_extend("keep", obj.env, config.cmake.configure_environment, config.cmake.environment)
	return ret
end

local _build_args = function(obj, build_directory)
	local args = { "--build" }
	table.insert(args, build_directory)
	if config.cmake.parallel_jobs then
		table.insert(args, "-j " .. tostring(config.cmake.parallel_jobs))
	end
	if #obj.buildArgs ~= 0 then
		for _, v in ipairs(obj.buildArgs) do
			table.insert(args, v)
		end
	elseif #config.cmake.build_args ~= 0 then
		for _, v in ipairs(config.cmake.build_args) do
			table.insert(args, v)
		end
	end
	if #obj.buildToolArgs ~= 0 or #config.cmake.build_tool_args ~= 0 then
		table.insert(args, "--")
		if #obj.buildToolArgs ~= 0 then
			for _, v in ipairs(obj.buildToolArgs) do
				table.insert(args, v)
			end
		elseif #config.cmake.build_tool_args ~= 0 then
			for _, v in ipairs(config.cmake.build_tool_args) do
				table.insert(args, v)
			end
		end
	end
	return args
end

local _build_command = function(obj, build_args)
	local ret = {}
	ret.cmd = config.cmake.cmake_path
	ret.args = table.concat(build_args, " ")
	ret.env = vim.tbl_deep_extend("keep", obj.env, config.cmake.configure_environment, config.cmake.environment)
	return ret
end

---Create configuration from variant
---@param source table
---@return CMakeGenerateOption
function VariantConfig:new(source)
	local obj = {}
	local subs = vim.tbl_deep_extend("keep", global_variant_subs, { ["${buildType}"] = source.buildType })

	obj.name = source.short
	obj.long_name = source.long
	obj.directory = utils.substitude(config.cmake.build_directory, subs)
	local configure_args = _configure_args(source, obj.directory)
	obj.generate_command = _configure_command(source, configure_args)
	local build_args = _build_args(source, obj.directory)
	obj.build_options = {
		{
			name = source.short,
			long_name = source.long,
			command = _build_command(source, build_args),
		},
	}

	setmetatable(obj, VariantConfig)
	return obj
end

function VariantConfig.cartesian_product(sets)
	local function collapse_result(res)
		local ret = {
			short = {},
			long = {},
			buildType = nil,
			linkage = nil,
			generator = nil,
			buildArgs = {},
			buildToolArgs = {},
			settings = {},
			env = {},
		}
		local is_default = true
		for _, v in ipairs(res) do
			if not v.default then
				is_default = false
			end
			ret.short[#ret.short + 1] = v.short
			ret.long[#ret.long + 1] = v.long
			ret.buildType = v.buildType or ret.buildType
			ret.linkage = v.linkage or ret.linkage
			ret.generator = v.generator or ret.generator
			ret.buildArgs = v.buildArgs or ret.buildArgs
			ret.buildToolArgs = v.buildToolArgs or ret.buildToolArgs
			for sname, sval in pairs(v.settings or {}) do
				ret.settings[sname] = sval
			end
			for ename, eres in pairs(v.env or {}) do
				ret.env[ename] = eres
			end
		end
		return VariantConfig:new(ret), is_default
	end
	local result = {}
	local set_count = #sets
	local function descend(depth)
		for k, v in pairs(sets[depth].choices) do
			if sets[depth].default ~= k then
				result.default = false
			end
			result[depth] = v
			result[depth].default = (k == sets[depth].default)
			if depth == set_count then
				coroutine.yield(collapse_result(result))
			else
				descend(depth + 1)
			end
		end
	end
	return coroutine.wrap(function()
		descend(1)
	end)
end

return VariantConfig
