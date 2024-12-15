local log = require("lunaR.logging")

local M = {}

--- Setup the plugin
--- @param user_opts? table
M.setup = function(user_opts)
    local config = require("lunaR.config")
    if user_opts then
        log.info("Setting user options")
        log.debug("User options: " .. vim.inspect(user_opts))
        config.set_user_opts(user_opts)
    end
end

return M
