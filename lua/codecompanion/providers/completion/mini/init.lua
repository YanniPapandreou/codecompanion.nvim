local omnifunc = require("codecompanion.providers.completion.default.omnifunc")

local M = {}

-- completefunc has the identical interface to omnifunc
M.completefunc = omnifunc.completefunc

return M
