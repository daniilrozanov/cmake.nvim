local config = require("cmake.config")

local api = vim.api

local M = {}

local cmake = {
  bufnr = nil,
  window = nil,
  jobid = nil,
}

local runnable

local scroll_to_bottom = function()
  local info = vim.api.nvim_get_mode()
  if info and (info.mode == "n" or info.mode == "nt") then
    vim.cmd("normal! G")
  end
end

local prepare_cmake_buf = function()
  if cmake.bufnr and api.nvim_buf_is_valid(cmake.bufnr) then
    api.nvim_buf_delete(cmake.bufnr, { force = true })
  end
  cmake.bufnr = api.nvim_create_buf(false, false)
end

local termopen = function(command, opts)
  -- For some reason termopen() doesn't like an empty env table
  if command.env and vim.tbl_isempty(command.env) then
    command.env = nil
  end
  vim.fn.termopen(command.cmd .. " " .. command.args, {
    -- detach = 1,
    cwd = command.cwd,
    env = command.env,
    clear_env = config.cmake_terminal.clear_env,
    on_stdout = function(_, data, _)
      api.nvim_buf_call(cmake.bufnr, scroll_to_bottom)
    end,
    on_exit = function(pid, code, event)
      if code == 0 then
        command.after_success()
        if config.cmake_terminal.close_on_exit == "success" or config.cmake_terminal.close_on_exit == true then
          if api.nvim_win_is_valid(cmake.window) then
            api.nvim_win_close(cmake.window, true)
          end
        end
        if config.notification.after == "success" or config.notification.after == true then
          vim.notify(vim.tbl_get(opts, "notify", "ok_message") or "CMake successfully completed", vim.log.levels.INFO)
        end
      else
        if config.notification.after == "failure" or config.notification.after == true then
          local msg = "CMake failed. Code " .. tostring(code)
          local opt_msg = vim.tbl_get(opts, "notify", "err_message")
          if type(opt_msg) == "string" then
            msg = opt_msg
          elseif type(opt_msg) == "function" then
            msg = opt_msg(code)
          end
          vim.notify(msg, vim.log.levels.ERROR)
        end
      end
    end,
  })
end

local open_window = function()
  if not cmake.bufnr then
    vim.notify("No CMake buffer created yet", vim.log.levels.INFO)
    return
  end
  cmake.window = api.nvim_open_win(cmake.bufnr, config.cmake_terminal.enter, {
    win = 0,
    split = config.cmake_terminal.split,
    height = config.cmake_terminal.size,
    width = config.cmake_terminal.size,
  })
end

M.cmake_execute = function(command, opts)
  opts = opts or {}

  prepare_cmake_buf()
  if config.cmake_terminal.open_on_start and not (cmake.window and api.nvim_win_is_valid(cmake.window)) then
    open_window()
  end
  vim.api.nvim_buf_call(cmake.bufnr, function()
    termopen(command, opts)
  end)
end

M.cmake_toggle = function()
  if cmake.window and api.nvim_win_is_valid(cmake.window) then
    api.nvim_win_close(cmake.window, true)
  else
    open_window()
  end
end

M.target_execute = function(command, opts)
  opts = opts or {}
  local bufnr = api.nvim_create_buf(true, false)
  api.nvim_open_win(bufnr, config.target_terminal.enter, {
    win = 0,
    split = config.target_terminal.split,
    height = config.target_terminal.size,
    width = config.target_terminal.size,
  })
  api.nvim_buf_call(bufnr, function()
    vim.cmd.terminal()
    api.nvim_chan_send(vim.bo.channel, command.cwd .. "/" .. command.cmd)
  end)
end

return M
