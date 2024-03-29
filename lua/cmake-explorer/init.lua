local config = require("cmake-explorer.config")
local runner = require("cmake-explorer.runner")
local Project = require("cmake-explorer.project")
local capabilities = require("cmake-explorer.capabilities")
local utils = require("cmake-explorer.utils")
local Path = require("plenary.path")
local pickers = require("cmake-explorer.telescope.pickers")
local notif = require("cmake-explorer.notification")

local M = {}

M.project = nil

local format_build_dir = function()
	if Path:new(config.build_dir):is_absolute() then
		return function(v)
			return Path:new(v.path):make_relative(vim.env.HOME)
		end
	else
		return function(v)
			return Path:new(v.path):make_relative(M.project.path)
		end
	end
end

function M.configure(opts)
	assert(M.project)
	opts = opts or {}
	pickers.configure(opts)
end

function M.configure_last(opts)
	if not M.project.current_config then
		notif.notify("No current configuration")
		return
	end
	runner.start(M.project:configure_command())
end

function M.build(opts)
	opts = opts or {}
	pickers.build(opts)
end

function M.build_last(opts)
	if not M.project.current_config then
		notif.notify("No current configuration")
		return
	end
	runner.start(M.project:build_command())
end

function M.setup(opts)
	opts = opts or {}

	config.setup(opts)
	capabilities.setup()

	M.project = Project:from_variants(config.default_variants)

	if not M.project then
		print("fuuuuuuuuuuuu")
		return
	end
end

return M
