local log = require("lunaR.logging")
local code = require("lunaR.extract-code")
local term = require("lunaR.terminal")

local M = {}

--- Send the current line to the terminal
M.send_line = function()
    log.debug("[send_line] Getting expression at cursor.")
    local _, _, expr = code.get_cursor_expression()
    if not expr then
        log.error("[send_line] No expression found.")
        return
    end

    log.debug(string.format("[send_line] Sending expression: %s", expr))
    term.send_to_r(expr)
end

return M
