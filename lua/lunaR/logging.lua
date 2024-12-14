local M = {}

M.levels = { DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4 }
M.current_level = M.levels.DEBUG

--- Set the logging level
--- @param level string
M.set_level = function(level)
    M.current_level = M.levels[level] or M.levels.DEBUG
end

--- Log a message if the level is sufficient
--- @param level string
--- @param msg string
local function log(level, msg)
    if M.levels[level] >= M.current_level then
        vim.api.nvim_out_write(string.format("[%s] %s\n", level, msg))
    end
end

M.debug = function(msg)
    log("DEBUG", msg)
end

M.info = function(msg)
    log("INFO", msg)
end

M.warn = function(msg)
    log("WARN", msg)
end

M.error = function(msg)
    log("ERROR", msg)
end

return M
