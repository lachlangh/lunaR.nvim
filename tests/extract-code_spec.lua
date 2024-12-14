local assert = require("luassert")
local it = require("plenary.busted").it

local send = require("lunaR.extract-code")
local logging = require("lunaR.logging")
logging.set_level("WARN")

local function test_cursor_expression(opts)
    vim.api.nvim_win_set_cursor(0, { opts.line, opts.col })
    local _, range, _ = send.get_cursor_expression()
    assert.are.same(opts.expected, range)
end

describe("send module with real R file", function()
    local bufnr = vim.api.nvim_create_buf(false, true)
    local lines = vim.fn.readfile("tests/fixtures/expressions.R")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    vim.api.nvim_win_set_buf(0, bufnr)

    it("should ignore comment and go to 2nd line", function()
        test_cursor_expression { line = 1, col = 0, expected = { 1, 0, 1, 11 } }
    end)

    it("should find simple expression on 2nd line", function()
        test_cursor_expression { line = 2, col = 0, expected = { 1, 0, 1, 11 } }
    end)

    it("should find piped expression on 3rd line", function()
        test_cursor_expression { line = 3, col = 0, expected = { 4, 0, 6, 10 } }
    end)

    it("should skip multiline commend", function()
        test_cursor_expression { line = 9, col = 0, expected = { 10, 0, 13, 1 } }
    end)

    it("should find entire function", function()
        test_cursor_expression { line = 11, col = 0, expected = { 10, 0, 13, 1 } }
    end)

    it("should find single line inside function", function()
        test_cursor_expression { line = 12, col = 0, expected = { 11, 2, 11, 12 } }
    end)

    it("should find entire for loop", function()
        test_cursor_expression { line = 16, col = 0, expected = { 15, 0, 17, 1 } }
    end)

    it("should find single line inside for loop", function()
        test_cursor_expression { line = 17, col = 0, expected = { 16, 2, 16, 10 } }
    end)

    it("should find entire ifelse statement", function()
        test_cursor_expression { line = 20, col = 0, expected = { 19, 0, 25, 1 } }
    end)

    it("should find single line inside if statement", function()
        test_cursor_expression { line = 21, col = 0, expected = { 20, 2, 20, 15 } }
    end)

    it("should find entire ifelse statement", function()
        test_cursor_expression { line = 24, col = 0, expected = { 19, 0, 25, 1 } }
    end)

    it("should find multiline piped expression inside ifelse statement", function()
        test_cursor_expression { line = 29, col = 0, expected = { 28, 2, 31, 12 } }
    end)

    it("should find multiline piped expression with internal comments", function()
        test_cursor_expression { line = 30, col = 0, expected = { 28, 2, 31, 12 } }
    end)

    it("should find nested function definition", function()
        test_cursor_expression { line = 37, col = 0, expected = { 36, 2, 38, 3 } }
    end)

    it("should find empty function", function()
        test_cursor_expression { line = 44, col = 0, expected = { 43, 0, 43, 28 } }
    end)

    it("should find empty for loop", function()
        test_cursor_expression { line = 47, col = 0, expected = { 46, 0, 46, 25 } }
    end)

    it("should find entire unbraced if statement", function()
        test_cursor_expression { line = 50, col = 0, expected = { 49, 0, 50, 15 } }
    end)

    it("should find entire unbraced if else statement", function()
        test_cursor_expression { line = 55, col = 0, expected = { 54, 0, 54, 18 } }
    end)


    vim.api.nvim_buf_delete(bufnr, { force = true })
end
)
