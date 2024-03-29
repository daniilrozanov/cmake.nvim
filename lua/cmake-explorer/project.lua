local config = require("cmake-explorer.config")
local Path = require("plenary.path")
local utils = require("cmake-explorer.utils")
local FileApi = require("cmake-explorer.file_api")

local VariantConfig = {}

VariantConfig.__index = VariantConfig

local variant_subs = {
  ["${workspaceFolder}"] = vim.loop.cwd(),
  ["${userHome}"] = vim.loop.os_homedir(),
}

function VariantConfig:new(obj)
  setmetatable(obj, VariantConfig)
  obj.subs = obj:_subs()
  obj.build_directory = obj:_build_directory()
  obj.configure_args = obj:_configure_args()
  obj.configure_command = obj:_configure_command()
  obj.build_args = obj:_build_args()
  obj.build_command = obj:_build_command()
  if not obj.fileapis[obj.build_directory] then
    local fa = FileApi:new(obj.build_directory)
    if fa and fa:exists() then
      fa:read_reply()
      obj.fileapis[obj.build_directory] = fa
    end
  end

  return obj
end

function VariantConfig:_subs()
  return vim.tbl_deep_extend("keep", variant_subs, { ["${buildType}"] = self.buildType })
end

function VariantConfig:_build_directory()
  return utils.substitude(config.build_directory, self.subs)
end

function VariantConfig:_configure_args()
  local args = {}
  if self.generator then
    table.insert(args, "-G " .. '"' .. self.generator .. '"')
  end
  if self.buildType then
    table.insert(args, "-DCMAKE_BUILD_TYPE=" .. self.buildType)
  end
  if self.linkage and string.lower(self.linkage) == "static" then
    table.insert(args, "-DCMAKE_BUILD_SHARED_LIBS=OFF")
  elseif self.linkage and string.lower(self.linkage) == "shared" then
    table.insert(args, "-DCMAKE_BUILD_SHARED_LIBS=ON")
  end
  for k, v in pairs(self.settings or {}) do
    table.insert(args, "-D" .. k .. "=" .. v)
  end
  table.insert(args, "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON")
  table.insert(
    args,
    "-B" .. Path:new(self.build_directory):make_relative(utils.substitude(config.source_directory, self.subs))
  )
  return args
end

function VariantConfig:_configure_command()
  local ret = {}
  ret.cmd = config.cmake_path
  ret.args = self.configure_args
  ret.cwd = variant_subs["${workspaceFolder}"]
  ret.env = vim.tbl_deep_extend("keep", self.env, config.configure_environment, config.environment)
  ret.after_success = function()
    utils.symlink_compile_commands(self.build_directory, variant_subs["${workspaceFolder}"])
    self.fileapis[self.build_directory]:read_reply()
  end
  ret.before_run = function()
    self.current_config_ref = self
    local fa = FileApi:new(self.build_directory)
    if not fa then
      return
    end
    if not fa:create() then
      return
    end
    self.fileapis[self.build_directory] = fa
    return true
  end
  return ret
end

function VariantConfig:_build_args()
  local args = { "--build" }
  table.insert(
    args,
    Path:new(self.build_directory):make_relative(utils.substitude(config.source_directory, self.subs))
  )
  if #self.buildArgs ~= 0 then
    for _, v in ipairs(self.buildArgs) do
      table.insert(args, v)
    end
  elseif #config.build_args ~= 0 then
    for _, v in ipairs(config.build_args) do
      table.insert(args, v)
    end
  end
  if #self.buildToolArgs ~= 0 or #config.build_tool_args ~= 0 then
    table.insert(args, "--")
    if #self.buildToolArgs ~= 0 then
      for _, v in ipairs(self.buildToolArgs) do
        table.insert(args, v)
      end
    elseif #config.build_tool_args ~= 0 then
      for _, v in ipairs(config.build_tool_args) do
        table.insert(args, v)
      end
    end
  end
  return args
end

function VariantConfig:_build_command()
  local ret = {}
  ret.cmd = config.cmake_path
  ret.args = self.build_args
  ret.cwd = variant_subs["${workspaceFolder}"]
  ret.env = vim.tbl_deep_extend("keep", self.env, config.configure_environment, config.environment)
  return ret
end

local function cartesian_product(sets)
  local function collapse_result(res)
    local ret = {
      short = {},
      long = {},
      buildType = nil,
      linkage = nil,
      generator = nil,
      buildArgs = {},
      buildToolArgs = {},
      settings = {},
      env = {},
    }
    local is_default = true
    for _, v in ipairs(res) do
      if not v.default then
        is_default = false
      end
      ret.short[#ret.short + 1] = v.short
      ret.long[#ret.long + 1] = v.long
      ret.buildType = v.buildType or ret.buildType
      ret.linkage = v.linkage or ret.linkage
      ret.generator = v.generator or ret.generator
      ret.buildArgs = v.buildArgs or ret.buildArgs
      ret.buildToolArgs = v.buildToolArgs or ret.buildToolArgs
      for sname, sval in pairs(v.settings or {}) do
        ret.settings[sname] = sval
      end
      for ename, eres in pairs(v.env or {}) do
        ret.env[ename] = eres
      end
    end
    ret.display = {}
    ret.display.short = table.concat(ret.short, config.variants_display.short_sep)
    ret.display.long = table.concat(ret.long, config.variants_display.short_sep)
    ret.default = is_default or nil
    return ret
  end
  local result = {}
  local set_count = #sets
  local function descend(depth)
    for k, v in pairs(sets[depth].choices) do
      if sets[depth].default ~= k then
        result.default = false
      end
      result[depth] = v
      result[depth].default = (k == sets[depth].default)
      if depth == set_count then
        coroutine.yield(collapse_result(result))
      else
        descend(depth + 1)
      end
    end
  end
  return coroutine.wrap(function()
    descend(1)
  end)
end

local Project = {}

Project.__index = Project

function Project:from_variants(variants)
  local obj =
  { headers = {}, display = { short_len = 10, long_len = 30 }, configs = {}, current_config = nil, fileapis = {} }
  for _, v in pairs(variants) do
    table.insert(obj.headers, v.description or "")
  end
  for v in cartesian_product(variants) do
    v.fileapis = obj.fileapis
    v.current_config_ref = obj.current_config
    v = VariantConfig:new(v)
    obj.display.short_len = math.max(obj.display.short_len, string.len(v.display.short))
    table.insert(obj.configs, v)
    if v.default then
      obj.current_config = v
    end
    if not obj.fileapis[v.build_directory] then
      local fa = FileApi:new(v.build_directory)
      if fa and fa:exists() then
        fa:read_reply()
        obj.fileapis[v.build_directory] = fa
      end
    end
  end
  setmetatable(obj, Project)
  return obj
end

function Project:from_presets(presets)
  local obj = { { 1, 3, ddf = "" } }
  return setmetatable(obj, self)
end

function Project:set_current_config(idx)
  self.current_config = self.configs[idx]
end

function Project:set_current_build() end

function Project:configure_command()
  return self.current_config.configure_command
end

function Project:current_configure_index()
  for k, v in ipairs(self.configs) do
    if v == self.current_config then
      return k
    end
  end
  return 1
end

function Project:current_build_index()
  if not self.current_config then
    return 1
  end
  if getmetatable(self.current_config) == VariantConfig then
    return 1
  end
end

function Project:configure_display_options()
  return self.display_options
end

function Project:build_command()
  if not self.current_config then
    return
  end
  if getmetatable(self.current_config) == VariantConfig then
    return self.current_config.build_command
  end
end

function Project:build_directory()
  if not self.current_config then
    return
  end
  return self.current_config.build_directory
end

function Project:list_configs()
  return self.configs
end

function Project:list_builds(opts)
  if getmetatable(self.current_config) == VariantConfig then
    return { self.current_config }
  end
end

return Project
