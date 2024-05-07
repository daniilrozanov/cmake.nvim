local config = require("cmake.config")
local VariantConfig = require("cmake.variants")
local FileApi = require("cmake.fileapi")
local utils = require("cmake.utils")
local constants = require("cmake.constants")
local uv = vim.uv

local Project = {}

local initialised = false

---@type CMakeGenerateOption[]
local configs = {}
---@type number|nil
local current_config = nil
---@type CMakeFileApi[]
local fileapis = {}

---@class CMakeGenerateOption Initial configuration, which defines generation stage, it's build stages, it's targets and other artifacts produced by `cmake -S <source_dir> -B <build_dir> ...` command
---@field generate_command CMakeCommand Command which will be executed on generate stage
---@field directory string Absolute path to build directory created after generate stage
---@field build_options CMakeBuildOption[] Build options available for this generate options. Each build option have it's generate option scope
---@field current_build number Current build option's index
---@field name string[] Parts of short name to display. Should be concatenated with delimiter
---@field long_name string[] Parts of long name to display. Should be concatenated with delimiter

---@class CMakeBuildOption Option corresponding to build stage
---@field command CMakeCommand Command which will be executed on build stage
---@field name string[] Parts of short name to display. Should be concatenated with delimiter
---@field long_name string[] Parts of long name to display. Should be concatenated with delimiter

---@class CMakeCommand Command table to pass to any kind of runner or task manager
---@field cmd string Path to executable command
---@field args string|nil Command's arguments
---@field env {[string]:string}[]|nil Environvemt variables
---@field cwd string Current working directory
---@field after_success function|nil Function which neends to be invoked after command succesfully executed

--- Set internal variables to default
local reset_internals = function()
  configs = {}
  current_config = nil
  fileapis = {}
  initialised = true
end

--- Set `after_success` function to each command which may be executed.
--- These functions do minimal to plugin works
local append_after_success_actions = function()
  local read_reply = function(v, not_presented)
    if (not_presented and not fileapis[v.directory]) or not not_presented then
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

--- Clear existing fileapis and read from available build directories
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
-- TODO: make variants order more stable. at least when reading from file

---Initialise project from variants
---@param variants table
function Project.from_variants(variants)
  local variants_copy = vim.deepcopy(variants)
  local list_variants = {}
  for k, v in pairs(variants_copy) do
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

--- Delete `CMakeCache.txt` and `CMakeFiles` from current build directory
function Project.clear_cache()
  local cd = Project.current_directory()
  local Path = require("plenary.path")
  Path:new(vim.fs.joinpath(cd, "CMakeCache.txt")):rm()
  Path:new(vim.fs.joinpath(cd, "CMakeFiles")):rm({ recursive = true })
  -- uv.fs_unlink(vim.fs.joinpath(Project.current_directory(), "CMakeCache.txt"), function(f_err, _)
  -- 	assert(f_err, f_err)
  -- uv.fs_unlink(vim.fs.joinpath(Project.current_directory(), "CMakeFiles"), function(d_err)
  -- 	assert(d_err, d_err)
  -- 	callback()
  -- end)
  -- end)
end

--- Get all project's generate configs
--- @return CMakeGenerateOption[]
function Project.generate_options()
  return configs
end

--- Get current generate option
---@return unknown
function Project.current_generate_option()
  assert(current_config, "No current project config")
  return configs[current_config]
end

---Get current generate option's index
---@return number|nil
function Project.current_generate_option_idx()
  return current_config
end

--- Set current generate option by index
--- @param idx number
function Project.set_current_generate_option(idx)
  assert(
    not (idx < 1 or idx > #configs),
    "Index is out of range. Index is " .. idx .. " for " .. #configs .. " config(s)"
  )
  current_config = idx
end

--- Current build option's index
---@return number
function Project.current_build_option_idx()
  return configs[current_config].current_build
end

---Current build option
---@return CMakeBuildOption|nil
function Project.current_build_option()
  if not Project.current_build_option_idx() then
    return nil
  end
  return configs[current_config].build_options[Project.current_build_option_idx()]
end

--- Set current build option by index
--- @param idx number
function Project.set_current_build_option(idx)
  local _size = #configs[current_config].build_options
  assert(not (idx < 1 or idx > _size), "Index is out of range. Index is " .. idx .. " for " .. _size .. "config(s)")
  configs[current_config].current_build = idx
end

---Current build directory (usually `build-<...>`)
---@return string|nil
function Project.current_directory()
  return current_config and configs[current_config].directory or nil
end

---Current fileapi
---@return CMakeFileApi|nil
local current_fileapi = function()
  if not Project.current_directory() or not fileapis[Project.current_directory()] then
    return nil
  end
  return fileapis[Project.current_directory()]
end

---Set current executable target by it's index
---@param idx number
function Project.set_current_executable_target(idx)
  assert(current_fileapi(), "current fileapi in nil")
  assert(
    not (idx < 1 or idx > #current_fileapi().targets),
    "Index is out of range. Index is " .. idx .. " for " .. #current_fileapi().targets .. " target(s)"
  )
  assert(current_fileapi().targets[idx].type == "EXECUTABLE", "target is not executable")
  current_fileapi().current_executable_target = idx
end

---Current executable target's index
---@return number|nil
function Project.current_executable_target_idx()
  local _curr_fileapi = current_fileapi()
  if not _curr_fileapi then
    return nil
  end
  return _curr_fileapi.current_executable_target
end

---Current executable target
---@return CMakeFileApiTarget|nil
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

---Targets for current generate option (configuration)
---@param opts {type: string|nil}|nil Filter parameters
---@return CMakeFileApiTarget[]|nil
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

--TODO: opts -> config identifier (which can be number, string or configuration table)

---Create `query.json` file so `cmake` will produce reply directory
---@param opts {idx:number, path:string, config:CMakeGenerateOption}|nil Specity configuration to generate query
---@param callback function Callback. Will be executed after query created or if it already exists
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
  reset_internals()
  local variants_path = vim.fs.joinpath(uv.cwd(), constants.variants_yaml_filename)
  utils.file_exists(variants_path, function(variants_exists)
    if variants_exists then
      utils.read_file(variants_path, function(variants_data)
        local yaml = require("cmake.lyaml").eval(variants_data)
        Project.from_variants(yaml)
      end)
    else
      Project.from_variants(config.variants)
    end
  end)
end

---Setup project, which means get capabilities, create configurations from presets or variants
---and read fileapis
---@param opts {first_time_only: boolean}|nil
function Project.setup(opts)
  opts = opts or {}
  if opts.first_time_only and initialised then
    return
  end
  if not initialised then
    require("cmake.capabilities").setup(function()
      do_setup(opts)
    end)
  else
    do_setup(opts)
  end
end

return Project
