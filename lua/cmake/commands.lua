local commandline = require("cmake.commandline")
local actions = require("cmake.actions")
local project = require("cmake.project")

local M = {}

local cmd = vim.api.nvim_create_user_command

local prefix = "CMake"

-- local _commands = {
-- 	generate = {
-- 		options = {
-- 			fresh = {},
-- 		},
-- 		action = actions.generate,
-- 	},
-- 	build = {
-- 		options = {
-- 			target = {
-- 				type = "table",
-- 				subtype = "string",
-- 				delimiter = ",",
-- 				source = function()
-- 					return vim.iter(project.current_targets())
-- 						:map(function(target)
-- 							return target.name
-- 						end)
-- 						:totable()
-- 				end,
-- 			},
-- 			clean = {},
-- 			j = { type = "number" },
-- 		},
-- 		action = actions.build,
-- 	},
-- 	select = {
-- 		commands = {
-- 			generate = {
-- 				action = actions.generate_select,
-- 			},
-- 			build = {
-- 				action = actions.build_select,
-- 			},
-- 			run = {
-- 				action = actions.run_target_select,
-- 			},
-- 		},
-- 	},
-- 	explain = {
-- 		commands = {
-- 			generate = {
-- 				action = actions.generate_select,
-- 			},
-- 			build = {
-- 				action = actions.build_select,
-- 			},
-- 		},
-- 	},
-- 	run = {
-- 		options = {}, -- any options are possible. passed to action as a single string
-- 		action = actions.run_target,
-- 	},
-- 	edit = {
-- 		commands = {
-- 			variants = {
-- 				action = actions.edit_variants,
-- 			},
-- 			-- settings = {},
-- 		},
-- 	},
-- 	toggle = {
-- 		action = actions.toggle,
-- 	},
-- }

local commands = {
	["Generate"] = {
		command = actions.generate,
		parse = true,
		default_opts = { fresh = false },
		cmd_opts = {
			desc = "Generate with last configuration",
			nargs = "*",
			complete = commandline.cmake_generate_complete,
		},
	},
	["GenerateExplain"] = {
		command = actions.generate_explain,
		parse = true,
		default_opts = { fresh = false },
		cmd_opts = {
			desc = "Explain current generate command",
			nargs = "*",
			complete = commandline.cmake_generate_complete,
		},
	},
	["GenerateSelect"] = {
		command = actions.generate_select,
		cmd_opts = { desc = "Select generate configuration" },
	},
	["Build"] = {
		command = actions.build,
		parse = true,
		cmd_opts = {
			desc = "Build with last configuration",
			nargs = "*",
			complete = commandline.cmake_build_complete,
		},
	},
	["BuildExplain"] = {
		command = actions.build_explain,
		parse = true,
		cmd_opts = {
			desc = "Explain current build command",
			nargs = "*",
			complete = commandline.cmake_build_complete,
		},
	},
	["BuildSelect"] = {
		command = actions.build_select,
		cmd_opts = { desc = "Select build configuration" },
	},
	["Run"] = {
		command = actions.run_target,
		cmd_opts = { desc = "Run current executable target", nargs = "*" },
	},
	["RunSelect"] = {
		command = actions.run_target_select,
		cmd_opts = { desc = "Select executable target" },
	},
	["Toggle"] = {
		command = actions.toggle,
		cmd_opts = { desc = "Toggle cmake terminal" },
	},
	["EditVariants"] = {
		command = actions.edit_variants,
		cmd_opts = { desc = "Edit variants" },
	},
}

M.register_commands = function()
	for k, v in pairs(commands) do
		cmd(prefix .. k, function(opts)
			local action_opts = v.default_opts or {}
			if v.parse then
				action_opts = vim.tbl_deep_extend("keep", commandline.parse(opts.args) or {}, action_opts)
			end
			v.command(action_opts)
		end, v.cmd_opts)
	end
end

return M
