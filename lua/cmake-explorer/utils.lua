local config = require("cmake-explorer.config")
local capabilities = require("cmake-explorer.capabilities")
local Path = require("plenary.path")

local utils = {}

utils.build_path = function(build_dir, source_dir)
	local build_path = Path:new(config.build_dir)
	if build_path:is_absolute() then
		return (build_path / build_dir):absolute()
	else
		return Path:new(build_path, build_dir):normalize()
	end
end

utils.substitude = function(str, subs)
	local ret = str
	for k, v in pairs(subs) do
		ret = ret:gsub(k, v)
	end
	return ret
end

function utils.symlink_compile_commands(src_path, dst_path)
	local src = Path:new(src_path, "compile_commands.json")
	if src:exists() then
		vim.cmd(
			'silent exec "!'
			.. config.cmake_path
			.. " -E create_symlink "
			.. src:normalize()
			.. " "
			.. Path:new(dst_path, "compile_commands.json"):normalize()
			.. '"'
		)
	end
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

utils.make_maplike_list = function(proj)
	local mt = {}
	mt.__index = function(t, k)
		for _, value in ipairs(t) do
			if proj(value) == k then
				return value
			end
		end
	end
	mt.__newindex = function(t, k, v)
		for key, value in ipairs(t) do
			if proj(value) == k then
				rawset(t, key, v)
				return
			end
		end
		rawset(t, #t + 1, v)
	end
	return mt
end

return utils
