-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v2.5/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}
local statusline = require "ui.statusline"

M.ui = {
  tabufline = {
    enabled = false,
  },
}

M.base46 = {
  theme = "catppuccin",
  {
    integrations = {
      "cmp",
      "git",
      "telescope",
      "trouble",
      "dap",
      "notify",
      "statusline",
      "notify",
      "todo",
    },
  },
  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
    FloatBorder = { link = "EndOfBuffer", bg = "None" },
    Enum = { link = "Macro" },
    Method = { link = "Normal" },
  },
}

-------------------------------------- highlight ------------------------------------------
require "ui.highlights"

return M
