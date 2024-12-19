local log = require("lunaR.logging")
local code = require("lunaR.R.code")
local term = require("lunaR.terminal")

local M = {}

--- Send the expression at the cursor to the terminal
--- @param move_cursor boolean [Whether to move the cursor to the next expression after sending the current line.]
M.execute_line = function(move_cursor)
    log.debug("Getting expression at cursor.")

    local win_id = vim.api.nvim_get_current_win()
    local buf_id = vim.api.nvim_win_get_buf(win_id)
    local row, _ = unpack(vim.api.nvim_win_get_cursor(win_id))
    row = row - 1
    log.fmt_debug("Gettig expression, cursor at %d:%d in buffer %d", row, 0, buf_id)

    local node = code.find_expression(buf_id, row)

    if not node then
        log.fmt_info("No expression found at row %d in buffer %d", row, buf_id)
        return
    end

    local node_text = code.get_node_info(node, buf_id).text
    log.fmt_debug("Found expression: %s", node_text:sub(1, 50))

    term.send_to_r(node_text)

    if not move_cursor then
        return
    end

    local next_node = code.get_next_expression(node, buf_id)

    if not next_node then
        log.debug("No next expression to move to.")
        return
    end

    local next_node_range = code.get_node_info(next_node, buf_id).range
    log.fmt_debug("Moving cursor to next expression at %d:%d", next_node_range[1], next_node_range[2])

    vim.api.nvim_win_set_cursor(win_id, { next_node_range[1] + 1, next_node_range[2] })
end

--- Sends all lines up to (and including) the line with the cursor to the terminal
--- Doesn't use the treesitter parser to do anything clever, just sends the lines as they are,
--- even if in the middle of a function or expression.
M.execute_to_line = function()
    local win_id = vim.api.nvim_get_current_win()
    local buf_id = vim.api.nvim_win_get_buf(win_id)
    local row, _ = unpack(vim.api.nvim_win_get_cursor(win_id))

    log.fmt_debug("Sending all lines up to %d in buffer %d", row, buf_id)

    local lines = vim.api.nvim_buf_get_lines(buf_id, 0, row, false)

    for _, line in ipairs(lines) do
        -- skip whitespace lines
        if line:match("^%s*$") then
            goto continue
        end

        term.send_to_r(line)
        ::continue::
    end

    log.debug("Finished sending lines.")
end

return M
