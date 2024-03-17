local config = require("cmake-explorer.config")
local capabilities = require("cmake-explorer.capabilities")
local Path = require("plenary.path")

local utils = {
	plugin_prefix = "CM",
}

utils.build_dir_name = function(params)
	if capabilities.is_multiconfig_generator(params.generator) then
		return config.build_dir_template[1]
	else
		local paths = {}
		for k, v in ipairs(config.build_dir_template) do
			local path = v:gsub("${buildType}", params.build_type)
			if k ~= 1 and config.build_dir_template.case then
				if config.build_dir_template.case == "lower" then
					path = string.lower(path)
				elseif config.build_dir_template.case == "upper" then
					path = string.upper(path)
				end
			end
			table.insert(paths, path)
		end
		return table.concat(paths, config.build_dir_template.sep)
	end
end

utils.build_path = function(params, source_dir)
	if type(params) == "string" then
		return params
	end
	local build_path = Path:new(config.build_dir)
	if build_path:is_absolute() then
		return (build_path / utils.build_dir_name(params)):absolute()
	else
		return Path:new(source_dir, build_path, utils.build_dir_name(params)):absolute()
	end
end

utils.generate_args = function(params, source_dir)
	local ret = {}

	if type(params) == "string" then
		table.insert(ret, "-B" .. Path:new(params):make_relative(source_dir))
	else
		if params.preset then
			table.insert(ret, "--preset " .. params.preset)
		else
			if params.generator and vim.tbl_contains(capabilities.generators(), params.generator) then
				table.insert(ret, "-G" .. params.generator)
			end

			params.build_type = params.build_type or config.build_types[1]
			if params.build_type then
				table.insert(ret, "-DCMAKE_BUILD_TYPE=" .. params.build_type)
			end

			table.insert(ret, "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON")

			if type(params.args) == "table" then
				for k, v in pairs(params.args) do
					table.insert(ret, "-D" .. k .. "=" .. v)
				end
			elseif type(params.args) == "string" then
				table.insert(ret, params.args)
			end
			table.insert(ret, "-B" .. Path:new(utils.build_path(params, source_dir)):make_relative(source_dir))
		end
	end
	return ret
end

utils.is_eq = function(val, cmp, if_eq, if_not_eq)
	if val == cmp then
		if if_eq then
			return if_eq
		else
			return val
		end
	else
		if if_not_eq then
			return if_not_eq
		else
			return nil
		end
	end
end

utils.is_neq = function(val, cmp, if_eq, if_not_eq)
	if val ~= cmp then
		if if_eq then
			return if_eq
		else
			return val
		end
	else
		if if_not_eq then
			return if_not_eq
		else
			return nil
		end
	end
end

return utils
