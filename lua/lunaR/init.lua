local log = require("lunaR.logging")
local keymaps = require("lunaR.keymaps")
local commands = require("lunaR.commands")
local config = require("lunaR.config")

local M = {}

--- Setup the plugin
--- @param user_opts? table
M.setup = function(user_opts)
    if user_opts then
        log.fmt_debug("Setting user options: %s", vim.inspect(user_opts))
        config.set_user_opts(user_opts)
    end

    -- Setup user commands for starting and stopping R
    commands.setup()

    -- Setup keymaps for R filetype
    vim.api.nvim_create_autocmd("FileType", {
        pattern = { "r" },
        callback = function()
            keymaps.setup()
        end,
    })
end

return M
