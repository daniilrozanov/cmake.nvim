local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local cmake_make_entry = require("cmake-explorer.telescope.make_entry")
local notif = require("cmake-explorer.notification")
local previewers = require("cmake-explorer.telescope.previewers")

local M = {}

M.build_dirs = function(opts)
	local cmake = require("cmake-explorer")
	pickers
			.new(opts, {
				prompt_title = "CMake Builds",
				finder = finders.new_table({
					results = cmake.project.fileapis,
					-- entry_maker = cmake_make_entry.gen_from_fileapi(opts),
					entry_maker = function(entry)
						return {
							value = entry,
							display = entry.path,
							ordinal = entry.path,
						}
					end,
					sorter = conf.generic_sorter(opts),
					-- attach_mappings = function(prompt_bufnr, map)
					-- 	actions.select_default:replace(function() end)
					-- 	return true
					-- end,
				}),
			})
			:find()
end

M.configure = function(opts)
	local cmake = require("cmake-explorer")
	local runner = require("cmake-explorer.runner")
	opts.layout_strategy = "vertical"
	opts.layout_config = {
		prompt_position = "top",
		preview_cutoff = 0,
		preview_height = 5,
		mirror = true,
	}
	pickers
			.new(opts, {
				default_selection_index = cmake.project:current_configure_index(),
				prompt_title = "CMake Configure Options",
				finder = finders.new_table({
					results = cmake.project:list_configs(),
					entry_maker = cmake_make_entry.gen_from_configure(opts),
				}),
				sorter = conf.generic_sorter(opts),
				previewer = previewers.configure_previewer(),
				attach_mappings = function(prompt_bufnr, map)
					actions.select_default:replace(function()
						actions.close(prompt_bufnr)
						local selection = action_state.get_selected_entry()
						cmake.project.current_config = selection.value
						runner.start(selection.value.configure_command)
					end)
					return true
				end,
			})
			:find()
end

M.build = function(opts)
	local cmake = require("cmake-explorer")
	local runner = require("cmake-explorer.runner")
	opts.layout_strategy = "vertical"
	opts.layout_config = {
		prompt_position = "top",
		preview_cutoff = 0,
		preview_height = 5,
		mirror = true,
	}
	pickers
			.new(opts, {
				default_selection_index = cmake.project:current_build_index(),
				prompt_title = "CMake Build Options",
				finder = finders.new_table({
					results = cmake.project:list_builds(),
					entry_maker = cmake_make_entry.gen_from_configure(opts),
				}),
				sorter = conf.generic_sorter(opts),
				previewer = previewers.build_previewer(),
				attach_mappings = function(prompt_bufnr, map)
					actions.select_default:replace(function()
						actions.close(prompt_bufnr)
						local selection = action_state.get_selected_entry()
						cmake.project.current_config = selection.value
						runner.start(selection.value.build_command)
					end)
					return true
				end,
			})
			:find()
end

return M
