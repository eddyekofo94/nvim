local M = {}

--- Check if a buffer is valid
---@param bufnr integer? The buffer to check, default to current buffer
---@return boolean # Whether the buffer is valid or not
function M.is_buf_valid(bufnr)
  local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufnr })
  if buftype ~= '' and buftype ~= 'quickfix' then
    return false
  end

  return vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buflisted
end

-- Get the names of all current listed buffers
function M.get_current_filenames()
  local listed_buffers = vim.tbl_filter(function(bufnr)
    return vim.bo[bufnr].buflisted and vim.api.nvim_buf_is_loaded(bufnr)
  end, vim.api.nvim_list_bufs())

  return vim.tbl_map(vim.api.nvim_buf_get_name, listed_buffers)
end

---Check if a buffer is empty
---@param buf integer? default to current buffer
---@return boolean
function M.is_empty(buf)
  buf = vim._resolve_bufnr(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return true
  end

  local line_count = vim.api.nvim_buf_line_count(buf)
  return line_count == 0
    or line_count == 1
      and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ''
end

---Get text within range in given buffer
---@param buf integer?
---@param start integer[] 0-based (line, col)
---@param finish integer[] 0-based (line, col), end-exclusive
---@return string[] lines text in range
function M.range(buf, start, finish)
  buf = vim._resolve_bufnr(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return {}
  end

  local lines = vim.api.nvim_buf_get_lines(buf, start[1], finish[1] + 1, false)
  local num_lines = #lines
  if num_lines == 0 then -- invalid range or empty buffer
    return lines
  end

  lines[num_lines] = lines[num_lines]:sub(1, finish[2])
  lines[1] = lines[1]:sub(start[2] + 1)

  return lines
end

M.close_buffer = function(force)
  local listed_bufs = vim.fn.getbufinfo({ buflisted = 1 })
  local bufnr = vim.api.nvim_get_current_buf()

  if #listed_bufs <= 1 and not force then
    vim.api.nvim_echo({
      { ' 󰈆  ', 'WarningMsg' },
      { 'Last buffer—keeping it open.', 'Normal' },
    }, false, {})
    return
  end

  local display_path = require('utils.fs').get_project_path()
  local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufnr })

  local alt = vim.fn.bufnr('#')
  if alt > 0 and vim.api.nvim_buf_is_valid(alt) and vim.bo[alt].buflisted then
    vim.cmd('buffer #')
  else
    if not pcall(vim.cmd, 'bnext') then
      vim.cmd('enew')
    end
  end

  local cmd = (force or buftype == 'terminal') and 'bdelete!'
    or 'confirm bdelete'
  if
    pcall(function()
      vim.cmd(string.format('silent! %s %d', cmd, bufnr))
    end)
  then
    vim.api.nvim_echo({
      { ' 󰆓  Closed: ', 'Special' },
      { display_path, 'Directory' },
    }, false, {})
  end
end

function M.close_tab(tabpage)
  local tabs = vim.api.nvim_list_tabpages()

  if #tabs > 1 then
    tabpage = tabpage or vim.api.nvim_get_current_tabpage()

    vim.t[tabpage].bufs = nil

    local tab_nr = vim.api.nvim_tabpage_get_number(tabpage)

    local success, err = pcall(function()
      vim.api.nvim_cmd({ cmd = 'tabclose', args = { tostring(tab_nr) } }, {})
    end)

    if not success then
      vim.notify('Tabclose failed: ' .. err, vim.log.levels.WARN)
    end
  else
    vim.notify('Last tab cannot be closed', vim.log.levels.INFO)
  end
end

return M
