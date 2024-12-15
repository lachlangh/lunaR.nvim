local M = {}

local opts = {
    r_repl = "R",
    r_batch = "Rscript",
    r_repl_default_args = { "--no-save", "--no-restore-data" },
}

--- Merge user options with default options
--- @param user_opts table
M.set_user_opts = function(user_opts)
    vim.tbl_extend("force", opts, user_opts)
end

--- Get the user options
--- @return table
M.get_user_opts = function()
    return opts
end

return M
