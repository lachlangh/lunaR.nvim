local actions = require("lunaR.actions")

local M = {}

M.setup = function(bufnr)
    local opts = { noremap = true, silent = true, buffer = bufnr }

    -- Execute current line
    vim.keymap.set(
        "n", "<space>xx", function() actions.execute_line(true) end,
        vim.tbl_extend("force", { desc = "Execute current line and move to next expression" }, opts)
    )

    vim.keymap.set(
        "n", "<space>l", function() actions.execute_line(false) end,
        vim.tbl_extend("force", { desc = "Execute current line" }, opts)
    )

    vim.keymap.set(
        "n", "<space>rtl", function() actions.execute_to_line() end,
        vim.tbl_extend("force", { desc = "Execute all lines up to the current line" }, opts)
    )
end

return M
