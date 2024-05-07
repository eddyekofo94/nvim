local M = {}
local utils = require "utils.general"

--- A provider function for showing the current progress of loading language servers
---@param opts? table options passed to the stylize function
---@return function # the function for outputting the LSP progress
-- @usage local heirline_component = { provider = require("astronvim.utils.status").provider.lsp_progress() }
-- @see astronvim.utils.status.utils.stylize
function M.lsp_progress(opts)
  -- local spinner = utils.get_spinner("LSPLoading", 1) or { "" }
  local spinner = { " ", " ", " ", "󰺕 ", " ", " " }
  return function()
    local Lsp = {}
    return utils.stylize(Lsp and (spinner[math.floor(vim.luv.hrtime() / 12e7) % #spinner + 1] .. table.concat({
      Lsp.title or "",
      Lsp.message or "",
      Lsp.percentage and "(" .. Lsp.percentage .. "%)" or "",
    }, " ")), opts)
  end
end

return M
