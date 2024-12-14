-- Behaviour of the R treesitter parser has been discovered from iterative exploration.
-- There may be some edge cases that are not covered by the current implementation.

local log = require("lunaR.logging")

local M = {}
local parsers = {}
local expr_parents = { "program", "braced_expression" }

--- Find the first node on the line for a given buffer and row
--- Assumes the buffer exists and the row is valid
--- @param bufnr number
--- @param row number [0-based]
--- @return TSNode|nil
local function first_node_on_line(bufnr, row)
    log.debug(string.format("[first_node_on_line] Finding first node on line %d in buffer %d", row, bufnr))
    local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
    log.debug(string.format("[first_node_on_line] Line content (truncated): `%s`", line:sub(1, 50)))

    local start_col = line:find("%S")
    if not start_col then
        log.debug("[first_node_on_line] No non-whitespace character found on line.")
        return nil
    end

    start_col = start_col - 1
    log.debug(string.format("[first_node_on_line] First non-whitespace character at column %d", start_col))

    local node = vim.treesitter.get_node({ bufnr = bufnr, pos = { row, start_col } })
    if not node then
        error(
            string.format("[first_node_on_line] No node found at row %d, column %d in buffer %d", row, start_col, bufnr),
            0)
    end

    if node:type() == "program" then
        error(string.format("[first_node_on_line] Unexpected program node found at row %d", row), 0)
    end

    return node
end

--- Find the next executable expression at the given row.
--- @param bufnr number
--- @param row number [0-based]
--- @param root TSNode
--- @return TSNode|nil
local function find_expression(bufnr, row, root)
    if row == 0 then
        log.debug(string.format("[find_expression] On the first row (buffer %d)", bufnr))
        local children = root:named_children()
        if #children == 0 then
            return nil
        end

        for i, child in ipairs(children) do
            log.debug(string.format("[find_expression] Child %d type: %s", i, child:type()))
            if child:type() ~= "comment" then
                return child
            end
        end
    end

    local n_rows = vim.api.nvim_buf_line_count(bufnr)
    log.debug(string.format("[find_expression] Rows in buffer: %d, current row: %d", n_rows, row))
    local node = first_node_on_line(bufnr, row)

    if not (row < n_rows) then
        return nil
    end

    if not node or node:type() == "comment" then
        return find_expression(bufnr, row + 1, root)
    end

    log.debug(string.format("[find_expression] Final node type: %s", node:type()))

    while not vim.tbl_contains(expr_parents, node:parent():type()) do
        node = node:parent()
        if not node then
            error(
                string.format("[find_expression] Unexpected nil node while finding expression at row %d in buffer %d",
                    row,
                    bufnr), 0)
        end
    end

    return node
end

---@class TSNodeRange
---@field start_row number
---@field start_col number
---@field end_row number
---@field end_col number

--- Get the expression at the cursor position (line) in the current buffer.
--- @return TSNode|nil, TSNodeRange|nil, string|nil [The range of the expression and its text, or nil if no expression is found.]
M.get_cursor_expression = function()
    local win_id = vim.api.nvim_get_current_win()
    local buf_id = vim.api.nvim_win_get_buf(win_id)
    local row, _ = unpack(vim.api.nvim_win_get_cursor(win_id))
    row = row - 1
    log.debug(string.format("[get_cursor_expression] Getting expression at row %d in buffer %d", row, buf_id))

    if not parsers[buf_id] then
        log.debug(string.format("[get_cursor_expression] Initializing Treesitter parser for buffer %d", buf_id))
        parsers[buf_id] = vim.treesitter.get_parser(buf_id, "r")
    end

    -- todo: handle parser errors
    local parser = parsers[buf_id]
    local tree = parser:parse()[1]
    local root = tree:root()

    local expr_node = find_expression(buf_id, row, root)
    if not expr_node then
        log.info(string.format("[get_cursor_expression] No expression found at row %d in buffer %d", row, buf_id))
        return nil, nil, nil
    end

    local expr_range = { expr_node:range() }
    log.debug(string.format("[get_cursor_expression] Found expression range: %d:%d - %d:%d",
        expr_range[1], expr_range[2], expr_range[3], expr_range[4]))
    local text_to_send = vim.treesitter.get_node_text(expr_node, buf_id)
    log.debug(string.format("[get_cursor_expression] Found expression: %s", text_to_send:sub(1, 50)))
    return expr_node, expr_range, text_to_send
end

return M
