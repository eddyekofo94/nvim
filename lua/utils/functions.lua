local cmd = vim.cmd
local fn = vim.fn

local M = {}

---Return OS
---@return string
M.getOS = function()
  local handle = io.popen "uname -s"
  if handle == nil then
    vim.notify("Error while opening handler", vim.log.levels.ERROR)
    return ""
  end
  local uname = handle:read "*a"
  handle:close()
  uname = uname:gsub("%s+", "")
  if uname == "Darwin" then
    return "Darwin"
  elseif uname == "NixOS" then
    return "NixOS"
  elseif uname == "Linux" then
    return "Linux"
  else
    return ""
  end
end

--- Check if the minimum Neovim version is satisfied
--- Expects only the minor version, e.g. "9" for 0.9.1
---@param version number
---@return boolean
M.isNeovimVersionsatisfied = function(version)
  return version <= tonumber(vim.version().minor)
end

---checks if a command is available
---@param command string
---@return boolean
M.isExecutableAvailable = function(command)
  return vim.fn.executable(command) == 1
end

---notify
---@param message string
---@param level integer
---@param title string
M.notify = function(message, level, title)
  local notify_options = {
    title = title,
    timeout = 2000,
  }
  vim.api.nvim_notify(message, level, notify_options)
end

-- delay notifications till vim.notify was replaced or after 500ms
--  REFC: 2024-07-22 - use lazy notify?
function M.lazy_notify()
  local notifs = {}
  local function temp(...)
    table.insert(notifs, vim.F.pack_len(...))
  end

  local orig = vim.notify
  vim.notify = temp

  local timer = vim.loop.new_timer()
  local check = vim.loop.new_check()

  local replay = function()
    timer:stop()
    check:stop()
    if vim.notify == temp then
      vim.notify = orig -- put back the original notify if needed
    end
    vim.schedule(function()
      ---@diagnostic disable-next-line: no-unknown
      for _, notif in ipairs(notifs) do
        vim.notify(vim.F.unpack_len(notif))
      end
    end)
  end

  -- wait till vim.notify has been replaced
  check:start(function()
    if vim.notify ~= temp then
      replay()
    end
  end)
  -- or if it took more than 500ms, then something went wrong
  timer:start(500, 0, replay)
end

-- Check if a variable is not empty nor nil
M.isNotEmpty = function(s)
  return s ~= nil and s ~= ""
end

--- Check if path exists
M.path_exists = function(path)
  return vim.loop.fs_stat(path)
end

-- Return telescope files command
M.project_files = function()
  local path = vim.loop.cwd() .. "/.git"
  if M.path_exists(path) then
    return "Telescope git_files"
  else
    return "Telescope find_files"
  end
end

-- toggle quickfixlist
M.toggle_qf = function()
  local windows = fn.getwininfo()
  local qf_exists = false
  for _, win in pairs(windows) do
    if win["quickfix"] == 1 then
      qf_exists = true
    end
  end
  if qf_exists == true then
    cmd "cclose"
    return
  end
  if M.isNotEmpty(fn.getqflist()) then
    cmd "copen"
  end
end

-- move over a closing element in insert mode
M.escapePair = function()
  local closers = { ")", "]", "}", ">", "'", '"', "`", "," }
  local line = vim.api.nvim_get_current_line()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local after = line:sub(col + 1, -1)
  local closer_col = #after + 1
  local closer_i = nil
  for i, closer in ipairs(closers) do
    local cur_index, _ = after:find(closer)
    if cur_index and (cur_index < closer_col) then
      closer_col = cur_index
      closer_i = i
    end
  end
  if closer_i then
    vim.api.nvim_win_set_cursor(0, { row, col + closer_col })
  else
    vim.api.nvim_win_set_cursor(0, { row, col + 1 })
  end
end

function M.map(mode, l, r, opts)
  opts = opts or {}
  vim.keymap.set(mode, l, r, opts)
end

---returns OS dependent path separator
---@return string
M.path_separator = function()
  local is_windows = vim.fn.has "win32" == 1
  if is_windows == true then
    return "\\"
  else
    return "/"
  end
end

---load user config file .nvim_config.lua
---@return table
M.load_user_config = function()
  local home = os.getenv "XDG_CONFIG_HOME"
    or os.getenv "HOME"
    or os.getenv "USERPROFILE"
    or (os.getenv "HOMEDRIVE" .. os.getenv "HOMEPATH")
  local config_file = home .. M.path_separator() .. ".nvim_config.lua"
  local ok, err = pcall(dofile, config_file)
  if not ok then
    M.notify("Can not load user config: " .. err, vim.log.levels.INFO, "core.utils")
    return {}
  else
    return dofile(config_file)
  end
end

---Merge two tables into the first table
---@param t1 table
---@param t2 table
---@return table
M.merge_tables = function(t1, t2)
  for k, v in pairs(t2) do
    if (type(v) == "table") and (type(t1[k] or false) == "table") then
      M.merge_tables(t1[k], t2[k])
    else
      t1[k] = v
    end
  end
  return t1
end

---returns the number of items in a table
---@param t table
---@return integer
M.table_length = function(t)
  local count = 0
  for _ in pairs(t) do
    count = count + 1
  end
  return count
end

---Search for TODO|HACK|FIXME|NOTE with rg and
---populate quickfixlist with the results
M.search_todos = function()
  local result
  result = vim.fn.system "rg --json --case-sensitive -w 'TODO|HACK|FIXME|NOTE|REFACTOR'"
  if result == nil then
    return
  end
  local lines = vim.split(result, "\n")
  local qf_list = {}

  for _, line in ipairs(lines) do
    if line ~= "" then
      local data = vim.fn.json_decode(line)
      if data ~= nil then
        if data.type == "match" then
          local submatches = data.data.submatches[1]
          table.insert(qf_list, {
            filename = data.data.path.text,
            lnum = data.data.line_number,
            col = submatches.start,
            text = data.data.lines.text,
          })
        end
      end
    end
  end

  if next(qf_list) ~= nil then
    vim.fn.setqflist(qf_list)
    vim.cmd "copen"
  else
    local utils = require "utils.functions"
    utils.notify("No results found!", vim.log.levels.INFO, "Search TODOs")
  end
end

return M
