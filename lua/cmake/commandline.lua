local project = require("cmake.project")

local M = {}

-- from https://github.com/akinsho/toggleterm.nvim/blob/main/lua/toggleterm/commandline.lua

-- Get a valid base path for a user provided path
-- and an optional search term
---@param typed_path string
---@return string|nil, string|nil
local get_path_parts = function(typed_path)
	if vim.fn.isdirectory(typed_path ~= "" and typed_path or ".") == 1 then
		-- The string is a valid path, we just need to drop trailing slashes to
		-- ease joining the base path with the suggestions
		return typed_path:gsub("/$", ""), nil
	elseif typed_path:find("/", 2) ~= nil then
		-- Maybe the typed path is looking for a nested directory
		-- we need to make sure it has at least one slash in it, and that is not
		-- from a root path
		local base_path = vim.fn.fnamemodify(typed_path, ":h")
		local search_term = vim.fn.fnamemodify(typed_path, ":t")
		if vim.fn.isdirectory(base_path) then
			return base_path, search_term
		end
	end

	return nil, nil
end

local complete_path = function(typed_path)
	-- Read the typed path as the base for the directory search
	local base_path, search_term = get_path_parts(typed_path or "")
	local safe_path = base_path ~= "" and base_path or "."

	local paths = vim.fn.readdir(safe_path, function(entry)
		return vim.fn.isdirectory(safe_path .. "/" .. entry)
	end)

	if not u.str_is_empty(search_term) then
		paths = vim.tbl_filter(function(path)
			return path:match("^" .. search_term .. "*") ~= nil
		end, paths)
	end

	return vim.tbl_map(function(path)
		return u.concat_without_empty({ base_path, path }, "/")
	end, paths)
end

local generate_options = {
	fresh = true,
}

local complete_value = function(values, values_opts, match)
	return function(typed_value)
		typed_value = typed_value or ""
		return vim.iter(values(values_opts))
			:filter(function(value)
				return not typed_value or #typed_value == 0 or value[match]:match("^" .. typed_value .. "*")
			end)
			:map(function(value)
				return value[match]
			end)
			:totable()
	end
end

local build_options = {
	clean = true,
	j = function()
		return {}
	end,
	target = complete_value(project.current_targets, {}, "name"),
}

local install_options = {
	explain = true,
	-- component = complete_value(project.current_components, {}, "name"),
	prefix = complete_path,
}

---@param options table a dictionary of key to function
---@return fun(lead: string, command: string, _: number):table
local function complete(options)
	---@param lead string the leading portion of the argument currently being completed on
	---@param command string the entire command line
	---@param _ number the cursor position in it (byte index)
	---@return table
	return function(lead, command, _)
		local parts = vim.split(lead, "=")
		local key = parts[1]
		local value = parts[2]
		if options[key] then
			if type(options[key]) == "function" then
				return vim.iter(options[key](value))
					:map(function(opt)
						return key .. "=" .. opt
					end)
					:totable()
			else
				return {}
			end
		else
			return vim.iter(options)
				:filter(function(option, _)
					return option:match(" " .. option .. "=") == nil
				end)
				:map(function(option, option_value)
					if type(option_value) == "boolean" and option_value then
						return option
					else
						return option .. "="
					end
				end)
				:totable()
		end
	end
end

---Take a users command arguments in format 'key1=value key2'
---and parse this into a table of arguments
---@see https://stackoverflow.com/a/27007701
---@param args string
---@return any
function M.parse(args)
	local result = {}
	if args then
		for _, part in ipairs(vim.split(args, " ")) do
			local arg = vim.split(part, "=")
			local key, value = arg[1], arg[2]
			if not value then
				result[key] = true
			else
				if key == "target" then
					result[key] = vim.split(value, ",")
				else
					result[key] = value
				end
			end
		end
	end
	return result
end

M.cmake_generate_complete = complete(generate_options)

M.cmake_build_complete = complete(build_options)

M.cmake_install_complete = complete(install_options)

return M
