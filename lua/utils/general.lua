local M = {}

---@type false|fun(bufname: string, filetype: string, buftype: string): string?,string?
local cached_icon_provider
--- Resolve the icon and color information for a given buffer
---@param bufnr integer the buffer number to resolve the icon and color of
---@return string? icon the icon string
---@return string? color the hex color of the icon
function M.icon_provider(bufnr)
  bufnr = bufnr or 0
  local filetype = vim.bo[bufnr].filetype

  local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
  if devicons_ok and devicons then
    local icon, color = devicons.get_icon_color_by_filetype(filetype, { default = true })
    return icon, color
  end

  return ''
end

--- Merge extended options with a default table of options
---@param default? table The default table that you want to merge into
---@param opts? table The new options that should be merged with the default table
---@return table # The merged table
function M.extend_tbl(default, opts)
  opts = opts or {}
  return default and vim.tbl_deep_extend("force", default, opts) or opts
end

--- Serve a notification with a custom title
---@param msg string The notification body
---@param level? string The type of the notification (:help vim.log.levels)
---@param opts? table The nvim-notify options to use (:help notify-options)
function M.notify(msg, level, opts)
  vim.schedule(function()
    if not level then
      level = "info"
    end
    vim.notify(msg, vim.log.levels[level:upper()], M.extend_tbl({ title = "Custom" }, opts))
  end)
end

--- Serve a notification once with a custom title
---@param msg string The notification body
---@param level? string The type of the notification (:help vim.log.levels)
---@param opts? table The nvim-notify options to use (:help notify-options)
function M.notify_once(msg, level, opts)
  vim.schedule(function()
    if not level then
      level = "info"
    end
    vim.notify_once(msg, vim.log.levels[level:upper()], M.extend_tbl({ title = "Custom" }, opts))
  end)
end

--- regex used for matching a valid URL/URI string
M.url_matcher =
  "\\v\\c%(%(h?ttps?|ftp|file|ssh|git)://|[a-z]+[@][a-z]+[.][a-z]+:)%([&:#*@~%_\\-=?!+;/0-9a-z]+%(%([.;/?]|[.][.]+)[&:#*@~%_\\-=?!+/0-9a-z]+|:\\d+|,%(%(%(h?ttps?|ftp|file|ssh|git)://|[a-z]+[@][a-z]+[.][a-z]+:)@![0-9a-z]+))*|\\([&:#*@~%_\\-=?!+;/.0-9a-z]*\\)|\\[[&:#*@~%_\\-=?!+;/.0-9a-z]*\\]|\\{%([&:#*@~%_\\-=?!+;/.0-9a-z]*|\\{[&:#*@~%_\\-=?!+;/.0-9a-z]*})\\})+"

--- Delete the syntax matching rules for URLs/URIs if set
---@param win integer? the window id to remove url highlighting in (default: current window)
function M.delete_url_match(win)
  if not win then
    win = vim.api.nvim_get_current_win()
  end
  for _, match in ipairs(vim.fn.getmatches(win)) do
    if match.group == "HighlightURL" then
      vim.fn.matchdelete(match.id, win)
    end
  end
  vim.w[win].highlighturl_enabled = false
end

--- Add syntax matching rules for highlighting URLs/URIs
---@param win integer? the window id to remove url highlighting in (default: current window)
function M.set_url_match(win)
  if not win then
    win = vim.api.nvim_get_current_win()
  end
  M.delete_url_match(win)
  vim.fn.matchadd("HighlightURL", M.url_matcher, 15, -1, { window = win })
  vim.w[win].highlighturl_enabled = true
end

return M
