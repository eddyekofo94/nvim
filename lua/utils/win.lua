local M = {}

---Set window height, without affecting cmdheight
---@param win integer window ID
---@param height integer window height
---@return nil
function M.win_safe_set_height(win, height)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end

  local win_above = vim.api.nvim_win_call(win, function()
    return vim.fn.win_getid(vim.fn.winnr('j'))
  end)
  local win_below = vim.api.nvim_win_call(win, function()
    return vim.fn.win_getid(vim.fn.winnr('k'))
  end)
  if win_above == win and win_below == win then
    return
  end

  local ch = vim.go.cmdheight
  vim.api.nvim_win_set_height(win, height)
  vim.go.cmdheight = ch
end

---Returns a function to save some attributes over a list of windows
---@param save_method fun(win: integer): any?
---@return fun(store: table<integer, any>, wins: integer[]?)
function M.save(save_method)
  ---@param store string|table<integer, any>
  ---@param wins? integer[] list of wins to restore, default to all windows in
  ---current tabpage
  return function(store, wins)
    if type(store) == 'string' then
      store = _G[store]
    end
    if not store then
      return
    end
    for _, win in ipairs(wins or vim.api.nvim_tabpage_list_wins(0)) do
      local ok, result = pcall(vim.api.nvim_win_call, win, function()
        return save_method(win)
      end)
      if ok then
        store[win] = result
      end
    end
  end
end

---Returns a function to restore the attributes of windows from `store`
---@param restore_method fun(win: integer, data: any): any?
---@return fun(store: table<integer, any>, wins: integer[]?)
function M.restore(restore_method)
  ---@param store string|table<integer, any>
  ---@param wins? integer[] list of wins to restore, default to all windows in
  ---current tabpage
  return function(store, wins)
    if type(store) == 'string' then
      store = _G[store]
    end
    if not store then
      return
    end

    for _, win in pairs(wins or vim.api.nvim_tabpage_list_wins(0)) do
      if not store[win] then
        goto continue
      end
      if not vim.api.nvim_win_is_valid(win) then
        store[win] = nil
        goto continue
      end

      pcall(vim.api.nvim_win_call, win, function()
        restore_method(win, store[win])
      end)
      ::continue::
    end
  end
end

M.save_views = M.save(function(_)
  return vim.fn.winsaveview()
end)

M.restore_views = M.restore(function(_, view)
  vim.fn.winrestview(view)
end)

M.save_heights = M.save(vim.api.nvim_win_get_height)
M.restore_heights = M.restore(M.win_safe_set_height)

M.save_widths = M.save(vim.api.nvim_win_get_width)
M.restore_widths = M.restore(vim.api.nvim_win_set_width)

---Save window ratios as { height_ratio, width_ratio } tuple
M.save_ratio = M.save(function(win)
  return {
    h = { vim.api.nvim_win_get_height(win), vim.go.lines }, -- window height, vim height
    w = { vim.api.nvim_win_get_width(win), vim.go.columns }, -- window width, vim width
  }
end)

---Restore window ratios, respect &winfixheight and &winfixwidth and keep
---command window height untouched
M.restore_ratio = M.restore(function(win, ratio)
  local h, vim_h = ratio.h[1], ratio.h[2]
  local w, vim_w = ratio.w[1], ratio.w[2]

  if vim.fn.win_gettype(win) == '' then
    M.win_safe_set_height(win, vim.fn.round(vim.go.lines * h / vim_h))
    vim.api.nvim_win_set_width(win, vim.fn.round(vim.go.columns * w / vim_w))
    return
  end

  -- Special window, set to original height & width instead of ratio
  vim.schedule(function()
    if not vim.api.nvim_win_is_valid(win) then
      return
    end
    M.win_safe_set_height(win, h)
    vim.api.nvim_win_set_width(win, w)
  end)
end)

---Check if a window is empty
---A window is considered 'empty' if its containing buffer is empty
---@param win integer? default to current window
---@return boolean
function M.is_empty(win)
  win = win or vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then
    return true
  end
  return require('utils.buf').is_empty(vim.api.nvim_win_get_buf(win))
end

--- Closes all windows in the current tab except the active one.
M.only = function()
  local success, err = pcall(vim.cmd, 'only')

  if success then
    vim.api.nvim_echo({ { 'Focusing current window', 'Normal' } }, false, {})
  else
    vim.notify(
      'Could not close all windows: ' .. tostring(err),
      vim.log.levels.ERROR
    )
  end
end

M.smart_close = function(force)
  local win_id = vim.api.nvim_get_current_win()
  local win_config = vim.api.nvim_win_get_config(win_id)
  local tab_wins = vim.api.nvim_tabpage_list_wins(0)
  local buftype = vim.api.nvim_get_option_value('buftype', { buf = 0 })
  local fs = require('utils.fs')

  if win_config.relative ~= '' then
    vim.api.nvim_win_close(win_id, false)
    return
  end

  if #tab_wins > 1 then
    local display_path = fs.get_project_path()
    local cmd = (force or buftype == 'terminal') and 'hide' or 'confirm close'

    local success, _ = pcall(vim.cmd, cmd)
    if success then
      vim.api.nvim_echo({
        { ' 󰖭  Closed Split: ', 'Special' },
        { display_path, 'Directory' },
      }, false, {})
    end
    return
  end

  require('utils.buf').close_tab()
end

M.close_others = function()
  local main_win = vim.api.nvim_get_current_win()
  local all_wins = vim.api.nvim_tabpage_list_wins(0)
  local names_to_report = {}

  for _, w in ipairs(all_wins) do
    if vim.api.nvim_win_is_valid(w) and w ~= main_win then
      local b = vim.api.nvim_win_get_buf(w)
      if b and vim.api.nvim_buf_is_valid(b) then
        local n = vim.api.nvim_buf_get_name(b)
        table.insert(
          names_to_report,
          (n ~= '') and vim.fn.fnamemodify(n, ':t') or '[No Name]'
        )
      end
    end
  end

  local ok = pcall(function()
    vim.cmd('confirm only')
  end)

  if ok and #names_to_report > 0 then
    local chunks = { { ' 󰖭  Closed: ', 'Special' } }
    for i, name in ipairs(names_to_report) do
      table.insert(chunks, { name, 'Directory' })
      if i < #names_to_report then
        table.insert(chunks, { ', ', 'Normal' })
      end
    end
    vim.api.nvim_echo(chunks, false, {})
  end
end

---Close floating windows or special windows (help, etc)
---@param k string key to fallback to if no special windows are closed
M.close_special = function(k)
  local current_win = vim.api.nvim_get_current_win()

  -- Only close current win if it's a floating window
  if vim.fn.win_gettype(current_win) == 'popup' then
    vim.api.nvim_win_close(current_win, true)
    return
  end

  -- Close help window if in help
  if vim.bo.filetype == 'help' then
    vim.cmd('close')
    return
  end

  -- Else close all focusable floating windows in current tab page
  local floats = vim
    .iter(vim.api.nvim_tabpage_list_wins(0))
    :filter(function(win)
      return vim.fn.win_gettype(win) == 'popup'
        and vim.api.nvim_win_get_config(win).focusable
        and not vim.tbl_contains(
          { 'cmd', 'dialog', 'msg', 'pager' },
          vim.bo[vim.fn.winbufnr(win)].ft
        )
    end)

  if not floats:peek() then
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes(k, true, true, true),
      'n',
      false
    )
    return
  end

  floats:each(function(win)
    vim.api.nvim_win_close(win, false)
  end)
end

return M
