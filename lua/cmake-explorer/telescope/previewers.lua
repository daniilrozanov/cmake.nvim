local previewers = require("telescope.previewers")
local config = require("cmake-explorer.config")

local M = {}

M.configure_previewer = function(opts)
  return previewers.new_buffer_previewer({
    title = "Configure Details",

    define_preview = function(self, entry)
      if self.state.bufname then
        return
      end
      local entries = {
        "Command:",
        config.cmake_path .. " " .. table.concat(entry.value.configure_args, " "),
      }
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, entries)
    end,
  })
end

M.build_previewer = function(opts)
  return previewers.new_buffer_previewer({
    title = "Build Details",

    define_preview = function(self, entry)
      if self.state.bufname then
        return
      end
      local entries = {
        "Command:",
        config.cmake_path .. " " .. table.concat(entry.value.build_args, " "),
      }
      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, entries)
    end,
  })
end

return M
