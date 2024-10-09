-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v2.5/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}
local stl = require "ui.statusline"
local highlights = require "ui.highlights"

M.ui = {
  tabufline = {
    enabled = false,
  },
  statusline = {
    enabled = false,
    theme = "default",
    separator_style = "default",
    order = { "mode", "file", "macro", "diagnostics", "%=", "lsp_msg", "%=", "git", "lsp", "info", "cwd", "cursor_pos" },
    modules = {
      -- cursor_pos = stl.line_info(),
      info = stl.info(),
      cursor_pos = stl.line_info(),
      -- file_info = stl.file_info(),
      macro = stl.macro(),
      -- git = stl.git_diff(),
      -- cwd = stl.cwd(),

      xyz = "hi",
      f = "%F",
    },
  },
}

M.base46 = {
  theme = "catppuccin",
  hl_add = highlights,
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
  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
    Enum = { link = "Macro" },
    Method = { link = "Normal" },
    WarningMsg = { fg = "orange" },
    EndOfBuffer = { fg = "black" },

    WhichKeyDesc = { fg = "pink" },
    WhichKeyGroup = { fg = "blue" },
  },
}

return M
