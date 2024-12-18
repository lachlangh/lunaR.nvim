-- Behaviour of the R treesitter parser has been discovered from iterative exploration.
-- There may be some edge cases that are not covered by the current implementation.

local log = require("lunaR.logging")

local M = {}
local parsers = {}
local expr_parents = { "program", "braced_expression" }

--- Ensure that the parser is initialized for the given buffer.
--- If the parser is not initialized, it will be initialized.
--- Throws an error if the parser cannot be initialized.
--- @param buf_id number
local function ensure_parser(buf_id)
    if not parsers[buf_id] then
        log.debug(string.format("[get_cursor_expression] Initializing Treesitter parser for buffer %d", buf_id))
        local ok, parser_or_err = pcall(vim.treesitter.get_parser, buf_id, "r")

        -- todo: think where to catch this error
        if not ok then
            error(
                string.format("[get_cursor_expression] Error initializing parser for buffer %d: %s", buf_id,
                    parser_or_err),
                0)
        end

        parsers[buf_id] = parser_or_err
    end
end

--- Parse the buffer and return the tree
--- @param buf_id number
--- @return TSNode
local function get_tree_root(buf_id)
    ensure_parser(buf_id)
    local parser = parsers[buf_id]
    local trees = parser:parse()
    local r_tree = trees[1]

    return r_tree:root()
end

--- Find the first node on the line for a given buffer and row
--- Assumes the buffer exists and the row is valid.
--- @param buf_id number
--- @param row number [0-based]
--- @return TSNode|nil
local function find_first_node(buf_id, row)
    log.debug(string.format("[find_first_node] Finding first node on line %d in buffer %d", row, buf_id))
    local line = vim.api.nvim_buf_get_lines(buf_id, row, row + 1, false)[1]
    log.debug(string.format("[find_first_node] Line content (truncated): `%s`", line:sub(1, 50)))

    local start_col = line:find("%S")
    if not start_col then
        log.debug("[find_first_node] Found empty line at row .. " .. row)
        return nil
    end

    start_col = start_col - 1 -- lua 1-based to TS 0-based
    log.debug(string.format("[find_first_node] First non-whitespace character at column %d", start_col))

    local node = vim.treesitter.get_node({ buf_id = buf_id, pos = { row, start_col } })

    if not node then
        log.debug(string.format("[find_first_node] No node found at row %d, column %d in buffer %d", row, start_col,
            buf_id))
        return nil
    end

    if node:type() == "program" then
        -- The algorithm should not find a program node if the logic in the function is correct.
        log.error(string.format("[find_first_node] Unexpected program node found at row %d", row))
        return nil
    end

    return node
end

--- Find the next executable expression at the given row.
--- @param buf_id number
--- @param row number [0-based]
--- @return TSNode|nil
M.find_expression = function(buf_id, row)
    ensure_parser(buf_id)
    -- If we are on the first row then TS returns the 'program' node, which is not useful.
    -- So we explicitly handle this case, retrieve the first valid child node from the root and return it.
    if row == 0 then
        log.debug(string.format("[find_expression] On the first row (buffer %d)", buf_id))
        local children = get_tree_root(buf_id):named_children()
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

    local n_rows = vim.api.nvim_buf_line_count(buf_id)
    log.debug(string.format("[find_expression] Rows in buffer: %d, current row: %d", n_rows, row))
    local node = find_first_node(buf_id, row)

    if not node or node:type() == "comment" then
        if row + 1 >= n_rows then
            log.debug("[find_expression] Reached end of buffer with no expression found.")
            return nil
        end

        return M.find_expression(buf_id, row + 1)
    end

    log.debug(string.format("[find_expression] Final node type: %s", node:type()))

    -- Now we search the tree upwards until we find a parent that is an expression.
    while not vim.tbl_contains(expr_parents, node:parent():type()) do
        node = node:parent()
        if not node then
            log.error(
                string.format("[find_expression] Unexpected nil node while finding expression at row %d in buffer %d",
                    row,
                    buf_id))
            return nil
        end
    end

    return node
end

--- Get the next expression in the current buffer. Will only search within the same parent node.
--- This means if the current node is inside a function definition, it will only get the next expression inside the same function.
--- If the current node is at the end of the parent node, it will return nil.
--- @param node TSNode?
--- @param buf_id number
--- @return TSNode|nil
M.get_next_expression = function(node, buf_id)
    ensure_parser(buf_id)
    if not node then
        log.debug("[get_next_expression] No current node provided.")
        return nil
    end

    if not vim.api.nvim_buf_is_valid(buf_id) then
        log.warn("[get_next_expression] Invalid buffer ID provided " .. buf_id)
        return nil
    end

    repeat
        log.debug("[get_next_expression] Getting next named sibling.")

        node = node:next_named_sibling()

        if not node then
            log.info("[get_next_expression] Reached end of parent node. No more expressions.")
            return nil
        end

        log.debug(string.format("[get_next_expression] Next node type: %s", node:type()))
    until node:type() ~= "comment"

    return node
end

--- Get the text and range of a given TSNode.
--- @param node TSNode
--- @param buf_id number
--- @return table {range = TSNodeRange, text = string}|nil
M.get_node_info = function(node, buf_id)
    local node_range = { node:range() }
    local node_text = vim.treesitter.get_node_text(node, buf_id)

    return { range = node_range, text = node_text }
end


return M
