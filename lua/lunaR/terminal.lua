-- get user options from config.
-- check that R executables in user options are installed.

local log = require("lunaR.logging")
local utils = require("lunaR.utils")
local config = require("lunaR.config").get_user_opts()

log.debug("User options: " .. vim.inspect(config))

local M = {}

local shared_terminal = {
    buf = nil,
    channel = nil,
}

--- Check R is installed
--- This function checks if R is installed by running the given command and checking the return code.
--- If the return code is 0, R is installed.
--- @param cmd string: Command to check (.e.g, `R` or `radian`)
--- @return boolean
local function check_r_installed(cmd)
    log.debug("Checking if R is installed with command: " .. cmd)
    local ok, obj_or_err = pcall(function()
        return vim.system({ cmd, "--version" }):wait()
    end)

    if not ok then
        log.error(string.format(
            "Error while checking if R is installed with command %s: %s", cmd, obj_or_err))
        return false
    end

    local obj = obj_or_err
    local exit_code = obj.code
    log.debug("R installation check result: " .. exit_code)

    if exit_code == 0 then
        -- get first line of stdout
        local version = obj.stdout:match("([^\n]+)")
        log.info(string.format("%s is installed. Version: %s", cmd, version))
    else
        log.warn(string.format("Executing `%s --version` returned exit code %d", cmd, exit_code))
    end

    return exit_code == 0
end

-- Ensure R executables are installed
if not check_r_installed(config.r_repl) then
    error("FATAL: R REPL executable is not installed or not found in PATH.", 0)
end

if not check_r_installed(config.r_batch) then
    log.warn("R Batch executable is not installed or not found in PATH.")
end


--- Execute an R command in a subprocess
--- @param cmd string: R command to execute
--- @return string: Output of the command
local function exec_r_cmd(cmd)
    local cat_cmd = 'cat(' .. cmd .. ')'
    return vim.system({ config.r_repl, "--slave", "-e", cat_cmd }):wait().stdout
end

--- Get the R home directory
--- This function executes the R command `path.expand("~")` to get the R home directory.
--- On Windows R uses relatively complex logic to determine the home directory, so this function
--- is used to get the home directory (according to R) in a platform-independent way.
--- @return string
local function get_r_home()
    log.debug("Getting R home directory")
    local r_home = exec_r_cmd('path.expand("~")')
    log.debug("R home directory is: " .. r_home)
    return r_home
end

--- Identify the `.Rprofile` file to be executed at startup.
---
--- This function reimplements the R runtime logic for identifying the user profile file,
--- following the R startup documentation. It searches for a user profile in the following order:
---
--- 1. If the `R_PROFILE_USER` environment variable is set, its value is expanded and used.
--- 2. If `R_PROFILE_USER` is not set, it looks for `.Rprofile` in the current global working directory.
--- 3. If no `.Rprofile` is found in the working directory, it looks for `.Rprofile` in the user's home directory.
---
--- Note:
--- - If the `--no-init-file` or `--vanilla` flag was passed to R during startup, this function may not locate
---   or execute the `.Rprofile`, impacting plugin functionality dependent on R's global state.
--- - The `exec_r_cmd` function is assumed to execute R code and return the result.
---
--- @return string|nil [The path to the `.Rprofile` file if found, or nil if no profile is found.]
local function find_local_rprofile()
    -- Get the global working directory
    local wd = vim.fn.getcwd(-1, -1)
    log.debug(string.format("Global working directory detected: %s", wd))

    -- Check if R_PROFILE_USER environment variable is set
    local user_profile_env = vim.env.R_PROFILE_USER
    if user_profile_env then
        log.info(string.format("R_PROFILE_USER environment variable set: %s", user_profile_env))

        -- Expand the user profile path using R's `path.expand` command
        local expanded = exec_r_cmd('path.expand("' .. user_profile_env .. '")')
        log.debug(string.format("Expanded R_PROFILE_USER path: %s", expanded))

        return expanded
    end

    -- Normalize and check for `.Rprofile` in the working directory
    local wd_profile = vim.fs.normalize(wd .. "/.Rprofile")
    local wd_profile_exists = utils.file_exists(wd_profile)
    log.debug(string.format("Checking for `.Rprofile` in working directory: %s", wd_profile))

    if wd_profile_exists then
        log.info("`.Rprofile` found in the current working directory.")
        return wd_profile
    end

    -- Normalize and check for `.Rprofile` in the home directory
    local home_profile = exec_r_cmd('path.expand("~/.Rprofile")')
    local home_profile_exists = utils.file_exists(home_profile)
    log.debug(string.format("Checking for `.Rprofile` in home directory: %s", home_profile))

    if home_profile_exists then
        log.info("`.Rprofile` found in the home directory.")
        return home_profile
    end

    -- No `.Rprofile` found
    log.warn("No `.Rprofile` file found in R_PROFILE_USER, working directory, or home directory.")
    return nil
end


--- Get the lunaR Rprofile file saved in the plugin installation directory
--- @return string
local function find_lunaR_rprofile()
    local plugin_location = debug.getinfo(1, "S").source

    if plugin_location:sub(1, 1) == "@" then
        plugin_location = plugin_location:sub(2)
        plugin_location = vim.fs.normalize(plugin_location .. "/../../..")
    else
        -- fallback for dev mode
        plugin_location = vim.fn.getcwd()
    end

    log.debug("Plugin location is: " .. plugin_location)

    local lunaR_rprofile = vim.fs.normalize(plugin_location .. "/scripts/.Rprofile")
    local lunaR_rprofile_exists = utils.file_exists(lunaR_rprofile)

    log.debug("Expected lunaR .Rprofile location: " .. lunaR_rprofile)

    if not lunaR_rprofile_exists then
        error("FATAL: Could not find lunaR Rprofile in plugin installation directory", 0)
    end

    log.info("Found lunaR Rprofile in plugin installation directory")

    return lunaR_rprofile
end

local user_rprofile = find_local_rprofile() or ""
local lunaR_rprofile = find_lunaR_rprofile()

local r_term_init_env = {
    R_PROFILE_USER = lunaR_rprofile,
    LUNAR_ORIG_RPROFILE = user_rprofile,
    LUNAR_TERM = "TRUE",
}

local function ensure_terminal()
    if not shared_terminal.buf or not vim.api.nvim_buf_is_valid(shared_terminal.buf) then
        -- save the current window id to restore it later
        local prev_win = vim.api.nvim_get_current_win()

        -- create a new terminal buffer
        shared_terminal.buf = vim.api.nvim_create_buf(false, true)
        log.debug("Created terminal buffer id: " .. shared_terminal.buf)

        -- open a new terminal window
        -- switch is set to true so that the terminal command opens in the terminal buffer
        local window_id = vim.api.nvim_open_win(shared_terminal.buf, true, { split = "right" })
        log.debug("Opened terminal window id: " .. window_id)

        local cmd = config.r_repl .. " " .. table.concat(config.r_repl_default_args, " ")
        log.debug("Starting R repl with command: " .. cmd)

        -- start the R repl in the terminal
        shared_terminal.chan = vim.fn.termopen(
            cmd,
            {
                env = r_term_init_env,
                on_exit = function(_, exit_code, _)
                    log.info("R repl exited with code: " .. exit_code)
                    shared_terminal.buf = nil
                    shared_terminal.chan = nil
                    log.debug("Cleared terminal buffer and channel")
                end,
            })

        log.info(string.format("Started R repl in terminal buffer %d with channel id: %d",
            shared_terminal.buf,
            shared_terminal.chan))

        -- restore focus to the previous window
        vim.api.nvim_set_current_win(prev_win)
    else
        log.debug(string.format("R repl is already running in terminal buffer %d, channel id %d",
            shared_terminal.buf, shared_terminal.chan))
    end

    return shared_terminal
end



M.start_r = function()
    ensure_terminal()
end

M.stop_r = function()
    if shared_terminal.buf and vim.api.nvim_buf_is_valid(shared_terminal.buf) then
        vim.fn.chanclose(shared_terminal.chan)
        vim.api.nvim_buf_delete(shared_terminal.buf, { force = true })
        shared_terminal.buf = nil
        shared_terminal.chan = nil
        log.info("Stopped R repl in terminal")
    else
        log.warn("R repl is not running in terminal")
    end
end

return M
