local assert = require("luassert")
local it = require("plenary.busted").it

local code = require("lunaR.R.code")
require("lunaR.logging").set_level("warn")

local function test_cursor_expression(opts)
    local node = code.find_expression(opts.bufnr, opts.line - 1)
    if not node then
        assert.are.same(opts.expected, nil)
        return
    end
    local node_info = code.get_node_info(node, opts.bufnr)

    assert.are.same(opts.expected, node_info.range)
end

local function test_next_expression(opts)
    local curr_node = code.find_expression(opts.bufnr, opts.line - 1)

    if not curr_node then
        assert.are.same(opts.expected, nil)
        return
    end

    local next_node = code.get_next_expression(curr_node, opts.bufnr)

    if not next_node then
        assert.are.same(opts.expected, nil)
        return
    end

    local node_info = code.get_node_info(next_node, opts.bufnr)
    assert.are.same(opts.expected, node_info.range)
end

describe("send module with real R file", function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    local lines = vim.fn.readfile("tests/fixtures/expressions.R")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_win_set_buf(0, bufnr)

    it("should ignore comment and go to 2nd line", function()
        test_cursor_expression { line = 1, col = 0, expected = { 1, 0, 1, 11 }, bufnr = bufnr }
    end)

    it("should find simple expression on 2nd line", function()
        test_cursor_expression { line = 2, col = 0, expected = { 1, 0, 1, 11 }, bufnr = bufnr }
    end)

    it("should find piped expression on 3rd line", function()
        test_cursor_expression { line = 3, col = 0, expected = { 4, 0, 6, 10 }, bufnr = bufnr }
    end)

    it("should skip multiline commend", function()
        test_cursor_expression { line = 9, col = 0, expected = { 10, 0, 13, 1 }, bufnr = bufnr }
    end)

    it("should find entire function", function()
        test_cursor_expression { line = 11, col = 0, expected = { 10, 0, 13, 1 }, bufnr = bufnr }
    end)

    it("should find single line inside function", function()
        test_cursor_expression { line = 12, col = 0, expected = { 11, 2, 11, 12 }, bufnr = bufnr }
    end)

    it("should find entire for loop", function()
        test_cursor_expression { line = 16, col = 0, expected = { 15, 0, 17, 1 }, bufnr = bufnr }
    end)

    it("should find single line inside for loop", function()
        test_cursor_expression { line = 17, col = 0, expected = { 16, 2, 16, 10 }, bufnr = bufnr }
    end)

    it("should find entire ifelse statement", function()
        test_cursor_expression { line = 20, col = 0, expected = { 19, 0, 25, 1 }, bufnr = bufnr }
    end)

    it("should find single line inside if statement", function()
        test_cursor_expression { line = 21, col = 0, expected = { 20, 2, 20, 15 }, bufnr = bufnr }
    end)

    it("should find entire ifelse statement", function()
        test_cursor_expression { line = 24, col = 0, expected = { 19, 0, 25, 1 }, bufnr = bufnr }
    end)

    it("should find multiline piped expression inside ifelse statement", function()
        test_cursor_expression { line = 29, col = 0, expected = { 28, 2, 31, 12 }, bufnr = bufnr }
    end)

    it("should find multiline piped expression with internal comments", function()
        test_cursor_expression { line = 30, col = 0, expected = { 28, 2, 31, 12 }, bufnr = bufnr }
    end)

    it("should find nested function definition", function()
        test_cursor_expression { line = 37, col = 0, expected = { 36, 2, 38, 3 }, bufnr = bufnr }
    end)

    it("should find empty function", function()
        test_cursor_expression { line = 44, col = 0, expected = { 43, 0, 43, 28 }, bufnr = bufnr }
    end)

    it("should find empty for loop", function()
        test_cursor_expression { line = 47, col = 0, expected = { 46, 0, 46, 25 }, bufnr = bufnr }
    end)

    it("should find entire unbraced if statement", function()
        test_cursor_expression { line = 50, col = 0, expected = { 49, 0, 50, 15 }, bufnr = bufnr }
    end)

    it("should find entire unbraced if else statement", function()
        test_cursor_expression { line = 55, col = 0, expected = { 54, 0, 54, 18 }, bufnr = bufnr }
    end)

    it("should send next line inside function started on blank line", function()
        test_cursor_expression { line = 60, col = 0, expected = { 60, 2, 60, 8 }, bufnr = bufnr }
    end)

    it("should not find expression on final line", function()
        test_cursor_expression { line = 70, col = 0, expected = nil, bufnr = bufnr }
    end)

    it("should fine entire piped expression when started on blank line", function()
        test_cursor_expression { line = 68, col = 0, expected = { 65, 0, 68, 11 }, bufnr = bufnr }
    end)

    it("should find next expression", function()
        test_next_expression { line = 1, col = 0, expected = { 4, 0, 6, 10 }, bufnr = bufnr }
    end)

    it("should find next statement inside function", function()
        test_next_expression { line = 36, col = 0, expected = { 36, 2, 38, 3 }, bufnr = bufnr }
    end)

    it("should find no next statement on last statement of a function", function()
        test_next_expression { line = 40, col = 0, expected = nil, bufnr = bufnr }
    end)

    it("should find no next statement on last statement of a file", function()
        test_next_expression { line = 69, col = 0, expected = nil, bufnr = bufnr }
    end)

    it("should find no next statement after last statement of a file", function()
        test_next_expression { line = 70, col = 0, expected = nil, bufnr = bufnr }
    end)

    vim.api.nvim_buf_delete(bufnr, { force = true })
end
)
