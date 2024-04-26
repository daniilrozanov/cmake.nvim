local config = require("cmake.config")
local VariantConfig = require("cmake.variants")
local FileApi = require("cmake.fileapi")
local utils = require("cmake.utils")
local constants = require("cmake.constants")
local uv = vim.uv or vim.loop

local Project = {}

local initialised = false

local configs = {}
local current_config = nil
local fileapis = {}

local reset_internals = function()
	configs = {}
	current_config = nil
	fileapis = {}
	initialised = true
end

local append_after_success_actions = function()
	local read_reply = function(v, not_presented)
		if (not_presented and not fileapis[v.directory]) or not not_presented then
			--TODO: replace to vim.fs.joinpath after nvim 0.10 release
			utils.symlink(v.directory .. "/compile_commands.json", uv.cwd())
			fileapis[v.directory] = { targets = {} }
			FileApi.read_reply(v.directory, function(target)
				table.insert(fileapis[v.directory].targets, target)
			end)
		end
	end
	for _, v in ipairs(configs) do
		v.generate_command.after_success = function()
			read_reply(v, false)
		end
		for _, bv in ipairs(v.build_options) do
			bv.command.after_success = function()
				read_reply(v, true)
			end
		end
	end
end

local init_fileapis = function()
	fileapis = {}
	for _, v in ipairs(configs) do
		if not fileapis[v.directory] then
			fileapis[v.directory] = { targets = {} }
			FileApi.exists(v.directory, function(fileapi_exists)
				if fileapi_exists then
					FileApi.read_reply(v.directory, function(target)
						table.insert(fileapis[v.directory].targets, target)
					end)
				end
			end)
		end
	end
end

-- TODO: validate yaml and fallback to config's variants if not valid
function Project.from_variants(variants)
	local list_variants = {}
	for k, v in pairs(variants) do
		table.insert(list_variants, v)
		list_variants[#list_variants]._name = k
	end
	table.sort(list_variants, function(a, b)
		return a._name < b._name
	end)
	for var, is_default in VariantConfig.cartesian_product(list_variants) do
		var.current_build = 1
		table.insert(configs, var)
		current_config = not current_config and is_default and #configs or current_config
	end
	if not current_config and #configs ~= 0 then
		current_config = 1
	end
	append_after_success_actions()
	init_fileapis()
end

function Project.generate_options(opts)
	opts = opts or {}
	return configs
end

--TODO: remove opts where it is useless
function Project.current_generate_option(opts)
	opts = opts or {}
	assert(current_config, "No current project config")
	return configs[current_config]
end

function Project.current_generate_option_idx()
	return current_config
end

function Project.set_current_generate_option(idx)
	current_config = idx
end

--TODO: check on out of range
function Project.current_build_option_idx()
	return configs[current_config].current_build
end

function Project.current_build_option()
	if not Project.current_build_option_idx() then
		return nil
	end
	return configs[current_config].build_options[Project.current_build_option_idx()]
end

function Project.set_current_build_option(idx)
	configs[current_config].current_build = idx
end

function Project.current_directory()
	return current_config and configs[current_config].directory or nil
end

local current_fileapi = function()
	if not Project.current_directory() or not fileapis[Project.current_directory()] then
		return nil
	end
	return fileapis[Project.current_directory()]
end

function Project.set_current_executable_target(idx)
	current_fileapi().current_executable_target = idx
end

function Project.current_executable_target_idx()
	local _curr_fileapi = current_fileapi()
	if not _curr_fileapi then
		return nil
	end
	return _curr_fileapi.current_executable_target
end

function Project.current_executable_target()
	local _curr_fileapi = current_fileapi()
	if not _curr_fileapi then
		return nil
	end
	local _curr_exe_target_idx = Project.current_executable_target_idx()
	if not _curr_exe_target_idx then
		return nil
	end
	return _curr_fileapi.targets[_curr_exe_target_idx]
end

function Project.current_targets(opts)
	opts = opts or {}
	local _curr_fileapi = current_fileapi()
	if not _curr_fileapi then
		return nil
	end
	if opts.type then
		return vim.tbl_filter(function(t)
			return t.type == opts.type
		end, _curr_fileapi.targets)
	end
	return _curr_fileapi.targets
end

function Project.create_fileapi_query(opts, callback)
	opts = opts or {}
	local path

	if type(opts.idx) == "number" then
		path = configs[opts.idx].directory
	elseif type(opts.path) == "string" then
		path = opts.path
		--TODO: compare getmetatable(opts.config) with VariantConfig (and PresetsConfig in future)
	elseif type(opts.config) == "table" then
		path = opts.config.directory
	else
		path = configs[current_config].directory
	end
	FileApi.query_exists(path, function(query_exists)
		if not query_exists then
			FileApi.create(path, function()
				callback()
			end)
		else
			callback()
		end
	end)
end

local do_setup = function(opts)
	local variants_path = vim.fs.joinpath(uv.cwd(), constants.variants_yaml_filename)
	utils.file_exists(variants_path, function(variants_exists)
		if variants_exists then
			utils.read_file(variants_path, function(variants_data)
				local yaml = require("cmake.lyaml").eval(variants_data)
				Project.from_variants(yaml)
			end)
		else
			Project.from_variants(config.cmake.variants)
		end
	end)
end

function Project.setup(opts)
	opts = opts or {}
	vim.notify(
		"Start setup. " .. vim.inspect(opts.first_time_only) .. " " .. tostring(initialised),
		vim.log.levels.INFO
	)
	if opts.first_time_only and initialised then
		vim.notify(
			"Setup abort. " .. vim.inspect(opts.first_time_only) .. " " .. tostring(initialised),
			vim.log.levels.INFO
		)
		return
	end
	reset_internals()
	if not initialised then
		require("cmake.capabilities").setup(function()
			do_setup(opts)
		end)
	else
		do_setup(opts)
	end
end

return Project
