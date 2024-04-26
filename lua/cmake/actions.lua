local pr = require("cmake.project")
local config = require("cmake.config")
local t = require("cmake.terminal")
local utils = require("cmake.utils")
local constants = require("cmake.constants")
local Path = require("plenary.path")

local uv = vim.uv or vim.loop

local M = {}

local default_generate_exe_opts = {
	notify = {
		ok_message = "CMake build finished",
		err_message = function(code)
			return "CMake generate failed with code " .. tostring(code)
		end,
	},
}

local default_build_exe_opts = {
	notify = {
		ok_message = "CMake build finished",
		err_message = function(code)
			return "CMake build failed with code " .. tostring(code)
		end,
	},
}

M.reset_project = function(opts)
	require("cmake.project").setup(opts)
end

M.generate = function(opts)
	local idx = pr.current_generate_option_idx()
	if not idx then
		vim.notify("CMake: no project to generate")
		return
	end
	pr.create_fileapi_query({ idx = idx }, function()
		vim.schedule(function()
			t.cmake_execute(pr.current_generate_option().generate_command, default_generate_exe_opts)
		end)
	end)
end

M.generate_select = function(opts)
	local items = pr.generate_options(opts)
	vim.ui.select(items, {
		prompt = "Select configuration to generate:",
		format_item = function(item)
			return table.concat(item.name, config.variants_display.short.sep)
		end,
	}, function(choice, idx)
		if not idx then
			return
		end
		pr.set_current_generate_option(idx)
		pr.create_fileapi_query({ idx = idx }, function()
			vim.schedule(function()
				t.cmake_execute(choice.generate_command, default_generate_exe_opts)
			end)
		end)
	end)
end

M.build = function(opts)
	if not pr.current_build_option_idx() then
		M.build_select(opts)
	else
		pr.create_fileapi_query({ idx = pr.current_build_option_idx() }, function()
			vim.schedule(function()
				t.cmake_execute(pr.current_build_option().command, default_build_exe_opts)
			end)
		end)
	end
end

M.build_select = function(opts)
	local items = pr.current_generate_option(opts).build_options
	vim.ui.select(items, {
		prompt = "Select build option to generate:",
		format_item = function(item)
			return table.concat(item.name, config.variants_display.short.sep)
		end,
	}, function(choice, idx)
		if not idx then
			return
		end
		pr.set_current_build_option(idx)
		pr.create_fileapi_query({ idx = idx }, function()
			vim.schedule(function()
				t.cmake_execute(choice.command, default_build_exe_opts)
			end)
		end)
	end)
end

M.run_tagret = function(opts)
	opts = opts or {}
	local _curr_exe_cmd = pr.current_executable_target()
	if not _curr_exe_cmd then
		M.run_tagret_select(opts)
	else
		local command = {
			cmd = Path:new(pr.current_directory(), _curr_exe_cmd.path):make_relative(uv.cwd()),
		}
		t.target_execute(command)
	end
end

M.run_tagret_select = function(opts)
	opts = opts or {}
	opts.type = "EXECUTABLE"
	local items = pr.current_targets(opts)
	vim.ui.select(items, {
		prompt = "Select tagret to run:",
		format_item = function(item)
			return item.name
		end,
	}, function(choice, idx)
		if not idx then
			return
		end
		pr.set_current_executable_target(idx)
		local command = {
			cmd = Path:new(pr.current_directory(), choice.path):make_relative(uv.cwd()),
		}
		t.target_execute(command)
	end)
end

M.toggle = function()
	t.cmake_toggle()
end

M.edit_variants = function()
	utils.file_exists(constants.variants_yaml_filename, function(variants_exists)
		if variants_exists then
			vim.schedule(function()
				vim.cmd(string.format("e %s", constants.variants_yaml_filename))
			end)
		else
			local default_yaml = require("cmake.lyaml").dump(config.cmake.variants)
			utils.write_file(constants.variants_yaml_filename, default_yaml, function()
				vim.schedule(function()
					vim.cmd(string.format("e %s", constants.variants_yaml_filename))
				end)
			end)
		end
	end)
end

return M
