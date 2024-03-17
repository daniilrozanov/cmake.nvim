local has_notify, notify = pcall(require, "notify")

local Notification = {}

function Notification.notify(msg, lvl, opts)
  opts = opts or {}
  if has_notify then
    opts.hide_from_history = true
    return notify(msg, lvl, opts)
  end
end

return Notification
