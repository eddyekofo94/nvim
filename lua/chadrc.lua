-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v2.5/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}
local stl = require "ui.statusline"
-- local highlights = require "ui.highlights"
local highlights = require "ui.hl"
local get_hl = highlights.get_hl

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
    --  INFO: 2024-10-09 - Default
    Comment = { italic = true },
    ["@comment"] = { italic = true },
    Enum = { link = "Macro" },
    Method = { link = "blue" },
    Special = { fg = "yellow" },
    -- PreProc = { fg = "orange" },
    SpecialChar = { fg = "orange" },
    WarningMsg = { link = "DiagnosticWarn" },
    DiagnosticInfo = { fg = { "cyan", "white", 30 } },
    EndOfBuffer = { fg = "black" },
    Search = { fg = "black", bg = "purple" },
    Identifier = { fg = "lavender" },
    Include = { fg = "purple" },
    Operator = { fg = "pink" },
    Pmenu = { bg = "darker_black" },
    Macro = { fg = "lavender" },
    CursorLine = { bg = { "black2", "black", 30 } },

    FocusedWindow = { fg = "white", bg = { "black", "darker_black", 45 } },
    UnfocusedWindow = { fg = { "white", "black", 20 } },

    TroublePreview = { fg = "red", bg = "lightbg", bold = true },

    TelescopeResultsTitle = { fg = { "black", "darker_black", 30 }, bg = { "black", "darker_black", 30 } },

    --  INFO: 2024-10-09 - Plugins
    WhichKeyDesc = { fg = "pink" },
    WhichKeyGroup = { fg = "blue" },

    --  INFO: 2024-10-10 - Treesitter
    ["@punctuation.bracket"] = { fg = "lavender" },
    ["@punctuation.delimiter"] = { fg = "white" },
    ["@variable.parameter"] = { fg = "teal" },
    -- ["@constant.builtin"] = { fg = "" },
    -- ["@character"] = { fg = "nord_blue" },

    ["@function.macro"] = { fg = "lavender" },
    ["@keyword.repeat"] = { fg = "purple" },
    ["@variable.member"] = { fg = "nord_blue" },
    ["@variable.member.key"] = { fg = "nord_blue" },
    ["@variable.builtin"] = { fg = "pink", italic = true },
    ["@module"] = { fg = "baby_pink" },
    ["@keyword.conditional"] = { fg = "red" },
    ["@function.method"] = { fg = "red" },
    ["@function.builtin"] = { fg = "orange" },
    ["@property"] = { fg = "lavender" },
    --  INFO: 2024-10-14 - Markup
    ["@markup.link"] = { fg = "cyan" },
    ["@markup.raw"] = { fg = "lavender" }, -- used for inline code in markdown and for doc in python (""")
    ["@markup.link.url"] = { fg = "cyan", italic = true, underline = true }, -- urls, links and emails
  },
  changed_themes = {
    catppuccin = {
      base_30 = {
        white = "#cdd6f4",
        lavender = "#B4BEFE",
        -- red = "#mycol",
        -- black2 = "#mycol",
      },
    },
  },
}

return M
