local config = require("cmake.config")
local commands = require("cmake.commands")
local autocmds = require("cmake.autocmds")
local utils = require("cmake.utils")
local constants = require("cmake.constants")

local uv = vim.uv

local M = {}

function M.setup(opts)
  opts = opts or {}
  config.setup(opts)
  if vim.fn.executable(config.cmake.cmake_path) then
    autocmds.setup()
    utils.file_exists(vim.fs.joinpath(uv.cwd(), constants.cmakelists), function(cmake_lists_exists)
      if cmake_lists_exists then
        --TODO: init autocommands needs to be related with project setup
        vim.schedule(function()
          autocmds.set_on_variants()
          commands.register_commands()
        end)
        require("cmake.project").setup()
      else
      end
    end)
  else
    vim.notify("CMake: " .. config.cmake.cmake_path .. " is not executable. Plugin is unavailable", vim.log.levels.WARN)
  end
end

return M
