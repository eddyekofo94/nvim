local NS_ID = vim.api.nvim_create_namespace "CustomWinSep"
local sep_wins = {}

local function clear_seps()
  for _, win in ipairs(sep_wins) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  sep_wins = {}
end

local function create_abs_line(width, height, row, col, char)
  local buf = vim.api.nvim_create_buf(false, true)
  -- If height > 1, it's a vertical line; we need to provide a list of characters
  local content = {}
  for i = 1, height do
    table.insert(content, char)
  end

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    focusable = false,
    style = "minimal",
    zindex = 60, -- Bumped up to ensure it clears all UI elements
  })

  -- For vertical lines, width is 1, so we set multiple lines
  -- For horizontal lines, height is 1, so we set one long string
  if height == 1 then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { string.rep(char, width) })
  else
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  end

  vim.wo[win].winhl = "Normal:ColorfulWinSep"
  table.insert(sep_wins, win)
end

_G.update_seps = function()
  clear_seps()

  local ignore_fts = { "fzf", "fzf-lua", "picker", "qf", "notify" }
  if vim.tbl_contains(ignore_fts, vim.bo.filetype) then
    return
  end

  local wins = vim.api.nvim_tabpage_list_wins(0)
  local valid_wins = {}
  for _, win in ipairs(wins) do
    if vim.api.nvim_win_get_config(win).relative == "" then
      table.insert(valid_wins, win)
    end
  end

  if #valid_wins <= 2 then
    return
  end
  if vim.api.nvim_win_get_config(0).relative ~= "" or vim.bo.filetype == "notification_history" then
    return
  end

  local win_id = vim.api.nvim_get_current_win()
  local pos = vim.api.nvim_win_get_position(win_id)
  local row, col = pos[1], pos[2]
  local win_w = vim.api.nvim_win_get_width(win_id)
  local win_h = vim.api.nvim_win_get_height(win_id)

  local max_cols, max_rows = vim.o.columns, vim.o.lines
  local bottom_limit = max_rows - ((vim.o.laststatus > 0) and 1 or 0) - vim.o.cmdheight

  -- 1. TOP & BOTTOM (Horizontal)
  if row > 0 then
    create_abs_line(win_w, 1, row - 1, col, "─")
  end
  if (row + win_h) < bottom_limit then
    create_abs_line(win_w, 1, row + win_h, col, "─")
  end

  -- 2. LEFT & RIGHT (Vertical)
  -- We use win_h for the height to ensure it's a single continuous floating window
  if col > 0 then
    create_abs_line(1, win_h, row, col - 1, "│")
  end
  if (col + win_w) < max_cols then
    create_abs_line(1, win_h, row, col + win_w, "│")
  end

  -- 3. JUNCTIONS (The Corners)
  if row > 0 and col > 0 then
    create_abs_line(1, 1, row - 1, col - 1, "┌")
  end
  if row > 0 and (col + win_w) < max_cols then
    create_abs_line(1, 1, row - 1, col + win_w, "┐")
  end
  if (row + win_h) < bottom_limit and col > 0 then
    create_abs_line(1, 1, row + win_h, col - 1, "└")
  end
  if (row + win_h) < bottom_limit and (col + win_w) < max_cols then
    create_abs_line(1, 1, row + win_h, col + win_w, "┘")
  end
end
-- 2. OPTIMIZED AUTOMATION
local group = vim.api.nvim_create_augroup("RosewaterWinSep", { clear = true })

-- We REMOVED CursorMoved. It only updates on Window switch or Resize.
vim.api.nvim_create_autocmd({
  "WinEnter",
  "BufEnter",
  "VimResized",
  "WinResized",
  "TextChanged",
  "TextChangedI", -- Update color when content changes
  "BufWritePost", -- Update color (back to Rosewater) when saved
}, {
  group = group,
  callback = function()
    vim.schedule(_G.update_seps)
  end,
})

-- Clear lines when leaving a window to ensure no "ghost" lines remain
vim.api.nvim_create_autocmd("WinLeave", {
  group = group,
  callback = function()
    clear_seps()
    vim.cmd "redraw"
  end,
})
