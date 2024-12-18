local terminal = require("lunaR.terminal")

local M = {}

M.setup = function()
    print("Setting up LunaR commands")
    vim.api.nvim_create_user_command("LunaR",
        function(command)
            local subcommand = command.args:lower()

            if subcommand == "start" then
                terminal.start_r()
            elseif subcommand == "stop" then
                terminal.stop_r()
            else
                vim.api.nvim_err_writeln("Invalid subcommand: " .. subcommand)
            end
        end,
        {
            nargs = 1,
            complete = function(_, _, _)
                return { "start", "stop" }
            end
        }
    )
end

return M
