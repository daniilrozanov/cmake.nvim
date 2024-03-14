local Enum = require("overseer.enum")

local M = {}

M.TAG = Enum.new({ "CONFIGURE", "BUILD", "INSTALL", "TEST", "PACK" })

return M
