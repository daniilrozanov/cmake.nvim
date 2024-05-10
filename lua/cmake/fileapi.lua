local capabilities = require("cmake.capabilities")
local scan = require("plenary.scandir")
local utils = require("cmake.utils")

local query_path_suffix = { ".cmake", "api", "v1", "query", "client-cmake", "query.json" }
local reply_dir_suffix = { ".cmake", "api", "v1", "reply" }

local FileApi = {}

---@class CMakeFileApi
---@field targets CMakeFileApiTarget[]
---@field current_executable_target? number Index for current executable target
---
---@class CMakeFileApiTarget
---@field id string Unique tagret id
---@field name string Target name
---@field type "EXECUTABLE"|"STATIC_LIBRARY"|"SHARED_LIBRARY"|"MODULE_LIBRARY"|"OBJECT_LIBRARY"|"INTERFACE_LIBRARY"|"UTILITY" Target type
---@field path string|nil Path to executable associated with target

function FileApi.create(path, callback)
  local query = vim.fs.joinpath(path, unpack(query_path_suffix))
  utils.file_exists(query, function(exists)
    if not exists then
      if capabilities.json.fileApi then
        vim.schedule(function()
          vim.fn.mkdir(vim.fs.dirname(query), "p")
          utils.write_file(query, vim.json.encode(capabilities.json.fileApi), callback)
        end)
      else
        vim.notify("Bad fileApi ", vim.log.levels.ERROR)
      end
    else
      callback()
    end
  end)
end

function FileApi.read_reply(path, callback)
  local reply_dir = vim.fs.joinpath(path, unpack(reply_dir_suffix))
  utils.file_exists(reply_dir, function(exists)
    if not exists then
      return
    end
    local ret = { targets = {} }
    --TODO: replace with uv scandir
    scan.scan_dir_async(reply_dir, {
      search_pattern = "index*",
      on_exit = function(results)
        if #results == 0 then
          return
        end
        utils.read_file(results[1], function(index_data)
          local index = vim.json.decode(index_data)
          for _, object in ipairs(index.objects) do
            if object.kind == "codemodel" then
              utils.read_file(vim.fs.joinpath(reply_dir, object.jsonFile), function(codemodel_data)
                local codemodel = vim.json.decode(codemodel_data)
                for _, target in ipairs(codemodel.configurations[1].targets) do
                  local work = vim.uv.new_work(utils.read_file_sync, function(target_data)
                    local target_json = vim.json.decode(target_data)
                    ---@type CMakeTarget
                    local _target = {
                      id = target_json.id,
                      name = target_json.name,
                      type = target_json.type,
                      path = nil,
                    }
                    if target_json.artifacts then
                      --NOTE: add_library(<name> OBJECT ...) could contain more than ohe object in artifacts
                      -- so maybe in future it will be useful to handle not only first one. Current behaviour
                      -- aims to get path for only EXECUTABLE targets
                      _target.path = target_json.artifacts[1].path
                    end
                    callback(_target)
                  end)
                  vim.uv.queue_work(work, vim.fs.joinpath(reply_dir, target.jsonFile))
                end
              end)
            end
          end
        end)
      end,
    })
    return ret
  end)
end

function FileApi.query_exists(path, callback)
  utils.file_exists(vim.fs.joinpath(path, unpack(query_path_suffix)), function(query_exists)
    callback(query_exists)
  end)
end

function FileApi.exists(path, callback)
  FileApi.query_exists(path, function(query_exists)
    if not query_exists then
      callback(false)
    else
      utils.file_exists(vim.fs.joinpath(path, unpack(reply_dir_suffix)), function(reply_exists)
        callback(reply_exists)
      end)
    end
  end)
end

return FileApi
