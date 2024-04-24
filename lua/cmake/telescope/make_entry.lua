local make_entry = require("telescope.make_entry")
local entry_display = require("telescope.pickers.entry_display")
local config = require("cmake.config")

local M = {}

M.gen_from_configure = function(opts)
  local project = require("cmake").project
  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = project.display.short_len + 5 },
      { remaining = true },
    },
  })
  local make_display = function(entry)
    vim.print(entry)
    return displayer({
      { entry.value.display.short, "TelescopeResultsIdentifier" },
      { entry.value.display.long,  "TelescopeResultsComment" },
    })
  end
  return function(entry)
    return make_entry.set_default_entry_mt({
      value = entry,
      ordinal = table.concat(entry.short, config.variants_display.short_sep),
      display = make_display,
    }, opts)
  end
end

M.gen_from_build = function(opts)
  local project = require("cmake").project
  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = project.display.short_len + 5 },
      { remaining = true },
    },
  })
  local make_display = function(entry)
    vim.print(entry)
    return displayer({
      { entry.value.display.short, "TelescopeResultsIdentifier" },
      { entry.value.display.long,  "TelescopeResultsComment" },
    })
  end
  return function(entry)
    return make_entry.set_default_entry_mt({
      value = entry,
      ordinal = table.concat(entry.short, config.variants_display.short_sep),
      display = make_display,
    }, opts)
  end
end

return M
