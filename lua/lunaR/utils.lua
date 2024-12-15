local M = {}

--- Check if a file exists
--- @param path string: The path to the file
--- @return boolean: True if the file exists, false otherwise
M.file_exists = function(path)
    return vim.uv.fs_stat(path) ~= nil
end

return M
