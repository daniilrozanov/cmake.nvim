local pr = require("cmake.project")
local config = require("cmake.config")
local t = require("cmake.terminal")
local utils = require("cmake.utils")
local constants = require("cmake.constants")
local Path = require("plenary.path")

local uv = vim.uv

local M = {}

local default_generate_exe_opts = {
  notify = {
    ok_message = "CMake generate finished",
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

local _explain = function(command)
  vim.notify(
    table.concat({
      table.concat(
        vim
          .iter(command.env or {})
          :map(function(k, v)
            if v:find(" ") then
              return k .. '="' .. v .. '"'
            end
            return k .. "=" .. v
          end)
          :totable(),
        " "
      ),
      command.cmd,
      command.args,
    }, " "),
    vim.log.levels.INFO
  )
end

--- Extends generate command by given options
---@param command table
---@param opts GenerateOpts
---@return table
local _extend_generate_command = function(command, opts)
  opts = opts or {}
  local new = vim.deepcopy(command)
  return new
end

--- Extends build command by given options
---@param command table
---@param opts BuildOpts
---@return table
local _extend_build_command = function(command, opts)
  local new = vim.deepcopy(command)
  if opts.j then
    new.args = new.args .. " -j " .. tostring(opts.j)
  end
  if opts.clean then
    new.args = new.args .. " --clean-first"
  end
  if opts.target and #opts.target ~= 0 then
    new.args = new.args .. " --target " .. table.concat(opts.target, " ")
  end
  return new
end

local _generate = function(option, opts)
  opts = opts or {}
  local main_path = function()
    pr.create_fileapi_query({}, function()
      vim.schedule(function()
        t.cmake_execute(_extend_generate_command(option.generate_command, opts), default_generate_exe_opts)
      end)
    end)
  end
  if opts.fresh then
    pr.clear_cache()
  end
  main_path()
end

local _for_current_generate_option = function(func)
  local idx = pr.current_generate_option_idx()
  if not idx then
    vim.notify("CMake: no configuration to generate", vim.log.levels.WARN)
  else
    func(pr.current_generate_option())
  end
end

---@class GenerateOpts
---@field fresh boolean|nil

--- Generate project with current generate option
--- @param opts GenerateOpts
M.generate = function(opts)
  opts = opts or {}
  _for_current_generate_option(function(option)
    _generate(option, opts)
  end)
end

--- Generate project with current generate option
--- @param opts GenerateOpts
M.generate_explain = function(opts)
  opts = opts or {}
  _for_current_generate_option(function(option)
    _explain(_extend_generate_command(option.generate_command, opts))
  end)
end

--- Generate project with current generate option
--- @param opts table|nil
M.generate_select = function(opts)
  opts = opts or {}
  local items = pr.generate_options(opts)
  vim.ui.select(items, {
    prompt = "Select configuration to generate:",
    format_item = function(item)
      return table.concat(item.name, config.variants_display.short.sep)
    end,
  }, function(_, idx)
    if not idx then
      return
    end
    pr.set_current_generate_option(idx)
  end)
end

local _for_current_build_option = function(func)
  local idx = pr.current_build_option()
  if not idx then
    vim.notify("CMake: no build configuration to generate", vim.log.levels.WARN)
  else
    func(pr.current_build_option())
  end
end

local _build = function(option, opts)
  opts = opts or {}
  pr.create_fileapi_query({}, function()
    vim.schedule(function()
      t.cmake_execute(_extend_build_command(option.command, opts), default_build_exe_opts)
    end)
  end)
end

---@class BuildOpts
---@field clean boolean|nil
---@field j number|nil
---@field target string[]|nil

--- Build project with current build option
--- @param opts BuildOpts
M.build = function(opts)
  opts = opts or {}
  _for_current_build_option(function(option)
    _build(option, opts)
  end)
end

--- Build project with current build option
--- @param opts BuildOpts
M.build_explain = function(opts)
  opts = opts or {}
  _for_current_build_option(function(option)
    _explain(_extend_build_command(option.command, opts))
  end)
end

---Change current build option
---@param opts any|nil
M.build_select = function(opts)
  local items = pr.current_generate_option().build_options
  vim.ui.select(items, {
    prompt = "Select build option to generate:",
    format_item = function(item)
      return table.concat(item.name, config.variants_display.short.sep)
    end,
  }, function(_, idx)
    if not idx then
      return
    end
    pr.set_current_build_option(idx)
  end)
end

local _run_target = function(opts)
  local command = {
    cmd = opts.path,
    cwd = pr.current_directory(),
  }
  t.target_execute(command)
end

---@class RunTargetOpts
---@field explain boolean|nil

--- Run target
--- @param opts RunTargetOpts
M.run_target = function(opts)
  opts = opts or {}
  local _curr_exe_cmd = pr.current_executable_target()
  if not _curr_exe_cmd then
    M.run_target_select(opts)
  else
    _run_target({ path = _curr_exe_cmd.path })
  end
end

--- Select target to run
M.run_target_select = function(opts)
  opts = opts or {}
  opts.type = "EXECUTABLE"
  local items = pr.current_targets(opts)
  vim.ui.select(items, {
    prompt = "Select tagret to run:",
    format_item = function(item)
      return item.name
    end,
  }, function(_, idx)
    if not idx then
      return
    end
    pr.set_current_executable_target(idx)
  end)
end

---Toggle CMake terminal window
M.toggle = function()
  t.cmake_toggle()
end

---Edit `.cmake-variants.yaml` file
M.edit_variants = function()
  utils.file_exists(constants.variants_yaml_filename, function(variants_exists)
    if variants_exists then
      vim.schedule(function()
        vim.cmd(string.format("e %s", constants.variants_yaml_filename))
      end)
    else
      local default_yaml = require("cmake.lyaml").dump(config.variants)
      utils.write_file(constants.variants_yaml_filename, default_yaml, function()
        vim.schedule(function()
          vim.cmd(string.format("e %s", constants.variants_yaml_filename))
        end)
      end)
    end
  end)
end

M.reset_project = function(opts)
  require("cmake.project").setup(opts)
end

return M
