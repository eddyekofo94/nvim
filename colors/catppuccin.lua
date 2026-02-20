-- Name:         catppuccin
-- Description:  Colorscheme for MΛCRO Neovim inspired by kanagawa-dragon @rebelot and mellifluous @ramojus
-- Author:       Bekaboo <kankefengjing@gmail.com>
-- Maintainer:   Bekaboo <kankefengjing@gmail.com>
-- License:      GPL-3.0
-- Last Updated: Wed 01 Oct 2025 01:33:37 AM EDT

-- Clear hlgroups and set colors_name {{{
vim.cmd.hi "clear"
vim.g.colors_name = "catppuccin"
-- }}}

-- Palette {{{
local green
local vibrant_green
local red
local yellow
local baby_pink
local blue
local one_bg3
local maroon
local teal
local one_bg2
local black
local black2
local darker_black
local one_bg
local sapphire
local white
local light_grey
local grey_fg2
local grey_fg
local grey
local orange
local pink
local purple
local cyan
local lavender
local line
local statusline
local nord_blue
local rosewater
local sun
local folder_bg
local dark_purple

if vim.go.bg == "dark" then
  -- Core Greys & Blacks
  black = { "#1E1D2D", 235 } -- nvim bg
  black2 = { "#252434", 234 }
  darker_black = { "#191828", 233 }
  one_bg = { "#2d2c3c", 236 }
  one_bg2 = { "#363545", 237 }
  one_bg3 = { "#3e3d4d", 240 }

  -- Text & Greys
  white = { "#cdd6f4", 253 }
  grey = { "#474656", 244 }
  grey_fg = { "#4e4d5d", 246 }
  grey_fg2 = { "#555464", 248 }
  light_grey = { "#605f6f", 250 }

  -- Accents
  red = { "#F38BA8", 204 }
  baby_pink = { "#ffa5c3", 223 }
  pink = { "#F5C2E7", 218 }
  maroon = { "#eba0ac", 211 } -- kept from bottom list
  rosewater = { "#f5e0dc", 224 } -- Your signature Rosewater

  green = { "#ABE9B3", 114 }
  vibrant_green = { "#b6f4be", 115 }
  teal = { "#B5E8E0", 116 }

  blue = { "#89B4FA", 111 }
  nord_blue = { "#8bc2f0", 110 }
  sapphire = { "#74c7ec", 117 }

  yellow = { "#FAE3B0", 222 }
  sun = { "#ffe9b6", 223 }
  orange = { "#F8BD96", 209 }
  purple = { "#d0a9e5", 183 }
  dark_purple = { "#c7a0dc", 176 }
  cyan = { "#89DCEB", 117 }
  lavender = { "#B4BEFE", 103 }

  -- UI Elements
  line = { "#383747", 236 }
  statusline = { "#232232", 234 }
  pmenu_bg = { "#ABE9B3", 114 }
  folder_bg = { "#89B4FA", 111 }
else
  -- Catppuccin Latte (Exact Hex)
  green = { "#40a02b", 70 }
  red = { "#d20f39", 160 }
  yellow = { "#df8e1d", 172 }
  sun = { "#df8e1d", 172 }
  baby_pink = { "#dc8a78", 173 }
  blue = { "#1e66f5", 27 }
  one_bg3 = { "#acb0be", 146 }
  maroon = { "#e64553", 167 }
  nord_blue = { "#5e81ac", 24 }
  teal = { "#179299", 30 }
  one_bg2 = { "#bcc0cc", 146 }
  black = { "#eff1f5", 255 }
  black2 = { "#e6e9ef", 254 }
  darker_black = { "#dce0e8", 253 }
  one_bg = { "#ccd0da", 251 }
  sapphire = { "#209fb5", 38 }
  white = { "#4c4f69", 237 }
  light_grey = { "#5c5f77", 240 }
  grey_fg2 = { "#6c6f85", 242 }
  grey_fg = { "#8c8fa1", 245 }
  grey = { "#9ca0b0", 247 }
  orange = { "#fe640b", 202 }
  pink = { "#ea76cb", 213 }
  purple = { "#8839ef", 93 }
  cyan = { "#04a5e5", 38 }
  lavender = { "#7287fd", 105 }
  line = { "#ccd0da", 251 }
  statusline = { "#e6e9ef", 254 }
end
-- stylua: ignore end
-- }}}

-- Terminal colors {{{
-- stylua: ignore start
vim.g.terminal_color_0  = black2[1]
vim.g.terminal_color_1  = red[1]
vim.g.terminal_color_2  = green[1]
vim.g.terminal_color_3  = yellow[1]
vim.g.terminal_color_4  = blue[1]
vim.g.terminal_color_5  = purple[1]
vim.g.terminal_color_6  = cyan[1]
vim.g.terminal_color_7  = white[1]
vim.g.terminal_color_8  = grey[1]
vim.g.terminal_color_9  = red[1]
vim.g.terminal_color_10 = green[1]
vim.g.terminal_color_11 = yellow[1]
vim.g.terminal_color_12 = blue[1]
vim.g.terminal_color_13 = purple[1]
vim.g.terminal_color_14 = cyan[1]
vim.g.terminal_color_15 = white[1]
-- stylua: ignore end
--- }}}

-- Highlight groups {{{1
local hlgroups = {
  -- UI {{{2
  ColorColumn = { bg = one_bg2 },
  Conceal = { bold = true, fg = grey },
  CurSearch = { link = "IncSearch" },
  Cursor = { bg = white, fg = black },
  CursorColumn = { link = "CursorLine" },
  CursorIM = { link = "Cursor" },
  CursorLineNr = { fg = white, bold = true },
  DebugPC = { bg = one_bg2 },
  DiffAdd = { fg = green },
  DiffAdded = { fg = green },
  DiffChange = { fg = sun },
  DiffChanged = { fg = yellow },
  DiffDelete = { fg = red },
  DiffDeleted = { fg = red },
  DiffNewFile = { fg = green },
  DiffOldFile = { fg = red },
  DiffRemoved = { fg = red },
  DiffText = { bg = one_bg3 },
  FloatBorder = { bg = darker_black, fg = line },
  FloatFooter = { bg = darker_black, fg = grey_fg },
  FloatTitle = { fg = white },
  FoldColumn = { fg = grey_fg },
  Folded = { bg = one_bg, fg = grey_fg2 },
  Ignore = { link = "NonText" },
  IncSearch = { bg = orange, fg = black },
  LineNr = { fg = grey_fg },
  MatchParen = { bg = one_bg3 },
  ModeMsg = { fg = red, bold = true },
  MoreMsg = { fg = blue },
  MsgArea = { fg = white },
  MsgSeparator = { bg = black },
  NonText = { fg = one_bg3 },
  Normal = { bg = black, fg = white },
  NormalFloat = { bg = darker_black, fg = white },
  NormalNC = { link = "Normal" },
  PmenuExtra = { fg = grey_fg },
  PmenuSbar = { bg = black2 },
  PmenuSel = { bg = black2, fg = "NONE", bold = true },
  PmenuThumb = { bg = grey },
  Question = { link = "MoreMsg" },
  QuickFixLine = { bg = one_bg },
  SignColumn = { fg = grey },
  SpellBad = { underdashed = true, sp = red },
  SpellCap = { underdashed = true, sp = yellow },
  SpellLocal = { underdashed = true, sp = blue },
  SpellRare = { underdashed = true, sp = purple },
  Substitute = { bg = red, fg = black },
  TabLine = { link = "StatusLineNC" },
  TabLineFill = { link = "Normal" },
  TabLineSel = { link = "StatusLine" },
  TermCursor = { fg = black, bg = red },
  Title = { bold = true, fg = blue },
  Underlined = { fg = teal, underline = true },
  VertSplit = { link = "WinSeparator" },
  Visual = { bg = one_bg3 },
  VisualNOS = { link = "Visual" },
  HighlightedYankRegion = {
    reverse = true,
  },
  Whitespace = { fg = one_bg3 },
  WildMenu = { link = "Pmenu" },
  WinBar = { bg = black, fg = white },
  WinBarNC = { bg = black, fg = grey_fg },
  WinSeparator = { fg = line },
  lCursor = { link = "Cursor" },
  -- }}}2

  -- Syntax
  -- Syntax {{{2
  Boolean = { fg = sun, italic = true, bold = true },
  Character = { link = "String" },
  Constant = { fg = orange, italic = true },
  Delimiter = { fg = orange },
  Error = { fg = red },
  Float = { link = "Number" },
  Function = { fg = purple },
  Number = { fg = orange },
  SpecialKey = { fg = grey },
  String = { fg = green },
  Todo = { fg = black, bg = blue, bold = true },
  Type = { fg = yellow },
  -- Final Syntax Logic Overrides {{{2
  PreProc = { fg = sapphire },
  PreCondit = { fg = purple },
  Include = { fg = dark_purple },
  Define = { fg = purple },

  Conditional = { fg = maroon },
  Repeat = { fg = red },
  Typedef = { fg = red },
  Exception = { fg = red },
  Statement = { fg = lavender },

  -- Keyword remains purple for structural elegance
  Keyword = { fg = pink, italic = true },
  -- }}}2
  -- }}}2
  -- Custom Overrides & Plugin Support {{{2
  Comment = { fg = grey_fg, italic = true },
  Enum = { link = "Macro" },
  Method = { link = "Function" }, -- In NvChad 'blue' is usually mapped to Function
  Special = { fg = sun },
  SpecialChar = { fg = orange },
  WarningMsg = { link = "DiagnosticWarn" },
  ErrorMsg = { fg = red },
  InfoMsg = { link = "DiagnosticInfo" },
  HintMsg = { link = "DiagnosticHint" },
  HighlightURL = { fg = teal, undercurl = true },

  -- Blended colors handled by selecting nearest NvChad equivalent
  EndOfBuffer = { fg = black },
  Search = { fg = black, bg = teal },
  Identifier = { fg = lavender },
  Operator = { fg = pink },
  Pmenu = { link = "NormalFloat" },
  Macro = { fg = lavender },
  CursorLine = { bg = black2 },
  Directory = { fg = folder_bg },

  SpecialWindowBG = { bg = darker_black },

  -- Window Focus logic
  FocusedWindow = { fg = white, bg = black },
  UnfocusedWindow = { fg = grey },

  -- Plugins
  TroublePreview = { fg = red, bg = one_bg, bold = true },

  -- Telescope
  TelescopeResultsTitle = { fg = black, bg = black },

  -- WhichKey
  WhichKeyDesc = { fg = pink },
  WhichKeyGroup = { fg = blue },
  WhichKeyFloat = { bg = black2 },

  -- Flash.nvim
  FlashLabel = { fg = green },
  FlashMatch = { fg = purple },
  FlashCurrent = { fg = sun },
  FlashPrompt = { link = "NormalFloat" },
  FlashBackdrop = { fg = light_grey },

  TSAnnotation = { fg = purple },
  TSAttribute = { fg = purple },
  TSBoolean = { link = "Boolean" },
  TSCharacter = { link = "Character" },
  TSCharacterSpecial = { link = "SpecialChar" },
  TSComment = { link = "Comment" },
  TSConditional = { fg = red },
  TSConstBuiltin = { fg = dark_purple },
  TSConstMacro = { fg = purple },
  TSConstant = { fg = white },
  TSConstructor = { fg = green },
  TSDebug = { link = "Debug" },
  TSDefine = { link = "Define" },
  TSEnvironment = { link = "Macro" },
  TSEnvironmentName = { link = "Type" },
  TSError = { link = "Error" },
  TSException = { fg = red },
  TSField = { fg = blue },
  TSFloat = { fg = purple },
  TSFuncBuiltin = { fg = orange },
  TSFuncMacro = { fg = green },
  TSFunction = { link = "Function" },
  TSFunctionCall = { fg = red },
  TSInclude = { fg = red },
  TSKeyword = { link = "Keyword" },
  TSKeywordFunction = { fg = purple },
  TSKeywordOperator = { fg = maroon },
  TSKeywordReturn = { fg = purple },
  TSLabel = { fg = blue },
  TSLiteral = { link = "String" },
  TSMath = { fg = blue },
  TSMethod = { link = "Method" },
  TSMethodCall = { fg = orange },
  TSNamespace = { link = "Method" },
  TSNone = { fg = white },
  TSNumber = { link = "Number" },
  TSOperator = { link = "Operator" },
  TSParameter = { fg = baby_pink },
  TSParameterReference = { fg = white },
  TSPreProc = { link = "PreProc" },
  TSProperty = { fg = lavender },
  TSPunctBracket = { fg = lavender },
  TSPunctDelimiter = { link = "Delimiter" },
  TSPunctSpecial = { fg = blue },
  TSRepeat = { fg = red },
  TSStorageClass = { fg = blue },
  TSStorageClassLifetime = { fg = blue },
  TSStrike = { fg = grey_fg },
  TSString = { link = "String" },
  TSStringEscape = { fg = green },
  TSStringRegex = { fg = green },
  TSStringSpecial = { link = "SpecialChar" },
  TSSymbol = { fg = nord_blue },
  TSTag = { fg = sun },
  TSTagAttribute = { fg = green },
  TSTagDelimiter = { fg = green },
  TSText = { fg = green },
  TSTextReference = { link = "Constant" },
  TSTitle = { link = "Title" },
  TSTodo = { link = "Todo" },
  TSType = { fg = yellow, bold = true }, -- Parameter
  TSTypeBuiltin = { fg = maroon },
  TSTypeDefinition = { fg = pink, bold = true },
  TSTypeQualifier = { fg = sun, bold = true },
  TSURI = { fg = vibrant_green },
  TSVariable = { fg = white },
  TSVariableBuiltin = { fg = pink, italic = true },

  ["@annotation"] = { link = "TSAnnotation" },
  ["@attribute"] = { link = "TSAttribute" },
  ["@boolean"] = { link = "TSBoolean" },
  ["@character"] = { link = "TSCharacter" },
  ["@character.special"] = { link = "TSCharacterSpecial" },
  ["@comment"] = { link = "TSComment" },
  ["@comment.documentation"] = { link = "TSComment" }, -- For comments documenting code
  ["@conceal"] = { link = "Conceal" },
  ["@conditional"] = { link = "TSConditional" },
  ["@constant"] = { link = "TSConstant" },
  ["@constant.builtin"] = { link = "TSConstBuiltin" },
  ["@constant.macro"] = { link = "TSConstMacro" },
  ["@constructor"] = { link = "TSConstructor" },
  ["@debug"] = { link = "TSDebug" },
  ["@define"] = { link = "TSDefine" },
  ["@error"] = { link = "TSError" },
  ["@exception"] = { link = "TSException" },
  ["@field"] = { link = "TSField" },
  ["@float"] = { link = "TSFloat" },
  ["@function"] = { link = "TSFunction" },
  ["@function.builtin"] = { link = "TSFuncBuiltin" },
  ["@function.call"] = { link = "TSMethod" },
  ["@function.macro"] = { link = "TSFuncMacro" },
  ["@include"] = { link = "TSInclude" },
  ["@keyword"] = { link = "TSKeyword" },
  ["@keyword.function"] = { link = "TSKeywordFunction" },
  ["@keyword.conditional"] = { link = "Conditional" },

  -- ["@spell"] = { fg = "orange" },
  ["@keyword.operator"] = { link = "TSKeywordOperator" },
  ["@keyword.return"] = { link = "TSKeywordReturn" },
  ["@label"] = { link = "TSLabel" },
  ["@math"] = { link = "TSMath" },
  ["@method"] = { link = "TSMethod" },
  ["@method.call"] = { link = "TSMethodCall" },
  ["@namespace"] = { link = "TSNamespace" },
  ["@none"] = { link = "TSNone" },
  ["@number"] = { link = "TSNumber" },
  ["@operator"] = { link = "TSOperator" },
  ["@parameter"] = { link = "TSParameter" },
  ["@parameter.reference"] = { link = "TSParameterReference" },
  ["@preproc"] = { link = "TSPreProc" },
  ["@property"] = { link = "TSProperty" },
  ["@punctuation.bracket"] = { link = "TSPunctBracket" },
  ["@punctuation.delimiter"] = { link = "TSPunctDelimiter" },
  ["@punctuation.special"] = { link = "TSPunctSpecial" },
  ["@repeat"] = { link = "TSRepeat" },
  ["@storageclass"] = { link = "TSStorageClass" },
  ["@storageclass.lifetime"] = { link = "TSStorageClassLifetime" },
  ["@strike"] = { link = "TSStrike" },
  ["@string"] = { link = "TSString" },
  ["@string.escape"] = { link = "TSStringEscape" },
  ["@string.regex"] = { link = "TSStringRegex" },
  ["@string.special"] = { link = "TSStringSpecial" },
  ["@symbol"] = { link = "TSSymbol" },
  ["@tag"] = { link = "TSTag" },
  ["@tag.attribute"] = { link = "TSTagAttribute" },
  ["@tag.delimiter"] = { link = "TSTagDelimiter" },
  ["@text"] = { link = "TSText" },
  ["@text.danger"] = { link = "TSDanger" },
  ["@text.diff.add"] = { link = "diffAdded" },
  ["@text.diff.delete"] = { link = "diffRemoved" },
  ["@text.emphasis"] = { link = "TSEmphasis" },
  ["@text.environment"] = { link = "TSEnvironment" },
  ["@text.environment.name"] = { link = "TSEnvironmentName" },
  ["@text.literal"] = { link = "TSLiteral" },
  ["@text.math"] = { link = "TSMath" },
  ["@text.note"] = { link = "TSNote" },
  ["@text.reference"] = { link = "TSTextReference" },
  ["@text.strike"] = { link = "TSStrike" },
  ["@text.strong"] = { link = "TSStrong" },
  ["@text.title"] = { link = "TSTitle" },
  ["@text.todo"] = { link = "TSTodo" },
  ["@text.todo.checked"] = { link = "Todo" },
  ["@text.todo.unchecked"] = { link = "Ignore" },
  ["@text.underline"] = { link = "TSUnderline" },
  ["@text.uri"] = { link = "TSURI" },
  ["@text.warning"] = { link = "TSWarning" },
  ["@todo"] = { link = "TSTodo" },
  ["@type"] = { link = "TSType" },
  ["@type.builtin"] = { link = "TSTypeBuiltin" },
  ["@type.definition"] = { link = "TSTypeDefinition" },
  ["@type.qualifier"] = { link = "TSTypeQualifier" },
  ["@uri"] = { link = "TSURI" },
  ["@variable"] = { link = "TSVariable" },
  ["@variable.builtin"] = { link = "TSVariableBuiltin" },
  ["@keyword.repeat"] = { fg = purple },
  ["@variable.member"] = { fg = nord_blue },
  ["@variable.member.key"] = { fg = nord_blue },
  ["@module"] = { fg = baby_pink },
  ["@function.method"] = { fg = red },
  ["@markup.link"] = { fg = cyan },
  ["@markup.raw"] = { fg = lavender }, -- used for inline code in markdown and for doc in python (""")
  ["@markup.link.url"] = { fg = vibrant_green, italic = true, underline = true }, -- urls, links and emails

  ["ColorfulWinSep"] = { fg = red },
  -- }}}2
  -- Variables & Members {{{2
  ["@variable.parameter"] = { fg = teal },
  -- }}}

  -- Constants & Literals {{{2
  ["@number.float"] = { fg = pink },
  -- }}}

  -- Keywords & Control Flow (Red/Purple Logic) {{{2
  ["@keyword.import"] = { link = "Include" },
  ["@keyword.storage"] = { fg = yellow },
  ["@keyword.directive"] = { fg = yellow },
  ["@keyword.exception"] = { fg = red },
  -- }}}

  ["@markup.heading"] = { fg = blue, bold = true },
  ["@markup.list"] = { fg = sun }, -- Your custom #ffe9b6
  ["@markup.quote"] = { bg = black2 },
  -- }}}

  -- Comments & Diff {{{2
  ["@comment.todo"] = { fg = black, bg = white, bold = true },
  ["@comment.warning"] = { fg = black2, bg = yellow },
  ["@comment.danger"] = { fg = black2, bg = red },

  ["@diff.plus"] = { fg = green },
  ["@diff.minus"] = { fg = red },
  ["@diff.delta"] = { fg = sun },
  -- }}}

  ["@string.regexp"] = { fg = pink },

  -- Markup (Markdown/Documentation)
  ["@markup.italic"] = { italic = true },
  ["@markup.strong"] = { bold = true },
  -- }}}
  -- Lua & LSP Overrides
  ["@function.call.lua"] = { fg = nord_blue },
  ["@variable.member.lua"] = { fg = blue },
  ["@constructor.lua"] = { fg = rosewater },
  ["@function.lua"] = { fg = purple },
  ["@functional.call.lua"] = { fg = nord_blue },
  ["@lsp.type.variable.lua"] = { fg = white },
  ["@lsp.type.parameter.lua"] = { fg = sun },
  ["@lsp.type.function.lua"] = { fg = sapphire },
  ["@lsp.type.property.lua"] = { fg = lavender },
  ["@lsp.type.method.lua"] = { fg = blue },
  ["@lsp.typemod.variable.global.lua"] = { fg = rosewater },
  ["@variable.parameter.lua"] = { fg = sun },
  ["@lsp.variable.lua"] = { fg = teal },

  -- bash
  ["@function.builtin.bash"] = { fg = purple, italic = true },
  ["@variable.parameter.bash"] = { fg = white },
  -- Add these to your hlgroups table

  -- Statusline Modules {{{2
  StatusLine = { bg = statusline, fg = white },
  StatusLineNC = { bg = black2, fg = grey_fg },

  -- Segment separators (if you use them)
  StatusLineSeparator = { fg = black2, bg = statusline },
  -- }}}2
  -- LSP Semantic Tokens {{{2
  ["@lsp.mod.readonly"] = { link = "Constant" },
  ["@lsp.mod.typeHint"] = { link = "Type" },
  ["@lsp.type.builtinConstant"] = { link = "@constant.builtin" },
  ["@lsp.type.comment"] = { fg = "NONE" },
  ["@lsp.type.macro"] = { fg = pink },
  ["@lsp.type.magicFunction"] = { link = "@function.builtin" },
  ["@lsp.type.method"] = { link = "@function.method" },
  ["@lsp.type.namespace"] = { link = "@module" },
  ["@lsp.type.parameter"] = { link = "@variable.parameter" },
  ["@lsp.type.selfParameter"] = { link = "@variable.builtin" },
  ["@lsp.type.variable"] = { fg = "NONE" },
  ["@lsp.typemod.function.builtin"] = { link = "@function.builtin" },
  ["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" },
  ["@lsp.typemod.function.readonly"] = { bold = true, fg = blue },
  ["@lsp.typemod.keyword.documentation"] = { link = "Special" },
  ["@lsp.typemod.method.defaultLibrary"] = { link = "@function.builtin" },
  ["@lsp.typemod.operator.controlFlow"] = { link = "@keyword.exception" },
  ["@lsp.typemod.operator.injected"] = { link = "Operator" },
  ["@lsp.typemod.string.injected"] = { link = "String" },
  ["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" },
  ["@lsp.typemod.variable.injected"] = { link = "@variable" },
  ["@lsp.typemod.variable.static"] = { link = "Constant" },

  -- Go (LSP & Tree-sitter) {{{2
  ["@lsp.property.go"] = { link = "Function" }, -- Blue
  ["@lsp.type.go"] = { link = "Keyword" }, -- Purple
  ["@lsp.type.keyword.go"] = { link = "Keyword" }, -- Purple
  ["@lsp.type.builtin.go"] = { fg = pink },
  ["@lsp.variable.member.go"] = { fg = blue },
  ["@type.go"] = { fg = purple, bold = true },
  ["@keyword.function.go"] = { fg = purple, italic = true },
  ["@variable.member.go"] = { fg = nord_blue },
  ["@variable.parameter.go"] = { fg = teal },
  ["@function.method.go"] = { fg = red }, -- Directs flow

  -- LSP Semantic Tokens (gopls)
  ["@lsp.type.interface.go"] = { fg = yellow, italic = true },
  ["@lsp.type.struct.go"] = { fg = purple },
  ["@lsp.type.variable.go"] = { fg = white },
  ["@lsp.type.parameter.go"] = { fg = pink },
  ["@lsp.type.function.go"] = { fg = blue },
  ["@lsp.type.method.go"] = { fg = blue },
  ["@lsp.type.namespace.go"] = { fg = orange }, -- Package names

  -- Specialized Modifiers
  ["@lsp.mod.readonly.go"] = { fg = orange, bold = true },
  ["@lsp.mod.format.go"] = { fg = rosewater }, -- Using your #f5e0dc

  -- Built-ins (make, append, panic, etc.)
  ["@function.builtin.go"] = { fg = orange, bold = true },
  -- }}}2

  -- LSP UI {{{2
  LspCodeLens = { fg = grey },
  LspInfoBorder = { link = "FloatBorder" },
  LspReferenceRead = { link = "LspReferenceText" },
  LspReferenceText = { bg = one_bg3 },
  LspReferenceWrite = { bg = one_bg3 },
  LspSignatureActiveParameter = { fg = sun },
  -- }}}
  -- Diagnostic {{{2
  DiagnosticError = { fg = red },
  DiagnosticHint = { fg = teal },
  DiagnosticInfo = { fg = cyan },
  DiagnosticOk = { fg = green },
  DiagnosticWarn = { fg = yellow },

  DiagnosticSignError = { fg = red },
  DiagnosticSignHint = { fg = teal },
  DiagnosticSignInfo = { fg = blue },
  DiagnosticSignWarn = { fg = yellow },

  DiagnosticUnderlineError = { sp = red, undercurl = true },
  DiagnosticUnderlineHint = { sp = teal, undercurl = true },
  DiagnosticUnderlineInfo = { sp = blue, undercurl = true },
  DiagnosticUnderlineWarn = { sp = yellow, undercurl = true },

  -- Virtual Text with subtle backgrounds
  DiagnosticVirtualTextError = { bg = black2, fg = red },
  DiagnosticVirtualTextHint = { bg = black2, fg = teal },
  DiagnosticVirtualTextInfo = { bg = black2, fg = blue },
  DiagnosticVirtualTextWarn = { bg = black2, fg = yellow },

  DiagnosticUnnecessary = {
    fg = grey,
    sp = teal,
    undercurl = true,
  },
  -- }}}
  -- Filetype {{{2
  -- Git
  gitHash = { fg = grey },

  -- Sh/Bash
  bashSpecialVariables = { link = "Constant" },
  shAstQuote = { link = "Constant" },
  shCaseEsac = { link = "Operator" },
  shDeref = { link = "Special" },
  shDerefSimple = { link = "shDerefVar" },
  shDerefVar = { link = "Constant" },
  shNoQuote = { link = "shAstQuote" },
  shQuote = { link = "String" },
  shTestOpr = { link = "Operator" },

  -- HTML
  htmlBold = { bold = true },
  htmlBoldItalic = { bold = true, italic = true },
  htmlH1 = { fg = red, bold = true },
  htmlH2 = { fg = red, bold = true },
  htmlH3 = { fg = red, bold = true },
  htmlH4 = { fg = red, bold = true },
  htmlH5 = { fg = red, bold = true },
  htmlH6 = { fg = red, bold = true },
  htmlItalic = { italic = true },
  htmlLink = { fg = blue, underline = true },
  htmlSpecialChar = { link = "SpecialChar" },
  htmlSpecialTagName = { fg = purple },
  htmlString = { link = "String" },
  htmlTagName = { link = "Tag" },
  htmlTitle = { link = "Title" },

  -- Markdown
  markdownBold = { bold = true },
  markdownBoldItalic = { bold = true, italic = true },
  markdownCode = { fg = green },
  markdownCodeBlock = { fg = green },
  markdownError = { link = "NONE" },
  markdownEscape = { fg = "NONE" },
  markdownH1 = { link = "htmlH1" },
  markdownH2 = { link = "htmlH2" },
  markdownH3 = { link = "htmlH3" },
  markdownH4 = { link = "htmlH4" },
  markdownH5 = { link = "htmlH5" },
  markdownH6 = { link = "htmlH6" },
  markdownListMarker = { fg = sun }, -- Using your custom Sun hex

  -- Checkhealth
  healthError = { fg = red },
  healthSuccess = { fg = green },
  healthWarning = { fg = yellow },
  helpHeader = { link = "Title" },
  helpSectionDelim = { link = "Title" },

  -- Quickfix
  qfFileName = { link = "Directory" },
  qfLineNr = { link = "LineNr" },
  -- }}}

  -- Plugins {{{2
  -- Gitsigns
  GitSignsAdd = { link = "DiffAdd" },
  GitSignsChange = { link = "DiffChange" }, -- Muted change indicator
  GitSignsDelete = { link = "DiffDelete" },
  GitSignsDeletePreview = { bg = one_bg },
  -- }}}
  -- Fugitive {{{2
  fugitiveHash = { link = "gitHash" },
  fugitiveHeader = { link = "Title" },
  fugitiveHeading = { link = "Title" },
  fugitiveStagedHeading = { fg = green, bold = true },
  fugitiveStagedModifier = { fg = green },
  fugitiveUnStagedHeading = { fg = yellow, bold = true },
  fugitiveUnstagedModifier = { fg = yellow },
  fugitiveUntrackedHeading = { fg = teal, bold = true },
  fugitiveUntrackedModifier = { fg = teal },
  -- }}}

  -- Telescope {{{2
  TelescopeBorder = { bg = black2, fg = line },
  TelescopeNormal = { bg = black2, fg = white },
  TelescopeMatching = { fg = red, bold = true },
  TelescopePromptBorder = { bg = one_bg, fg = line },
  TelescopePromptNormal = { bg = one_bg, fg = white },
  TelescopeResultsClass = { link = "Structure" },
  TelescopeResultsField = { link = "@variable.member" },
  TelescopeResultsMethod = { link = "Function" },
  TelescopeResultsStruct = { link = "Structure" },
  TelescopeResultsVariable = { link = "@variable" },
  TelescopeSelection = { link = "Visual" },
  TelescopeTitle = { bg = teal, fg = black },
  -- }}}

  -- INFO: nvchad colour
  PickerBorder = { fg = darker_black, bg = darker_black },
  PickerNormal = { fg = white, bg = darker_black },
  PickerListCursorLine = { bg = black2, bold = true },

  SnacksPickerBorder = { fg = darker_black, bg = darker_black },
  SnacksPickerTitle = { fg = darker_black, bg = red },
  SnacksPickerListCursorLine = { bg = black2, bold = true },
  SnacksPickerBufType = { bg = red },
  SnacksPickerPreviewBorder = { fg = darker_black, bg = darker_black },
  SnacksPickerPreview = { bg = darker_black },
  SnacksPickerPreviewTitle = { fg = darker_black, bg = green },
  SnacksPickerBoxBorder = { fg = darker_black, bg = darker_black },
  SnacksPickerBox = { fg = white, bg = darker_black },
  SnacksPickerInputBorder = { fg = darker_black, bg = darker_black },
  SnacksPickerInputSearch = { fg = red, bg = darker_black },
  SnacksPickerInput = { bg = darker_black },
  SnacksPickerList = { bg = darker_black },
  SnacksPickerListTitle = { fg = darker_black, bg = darker_black },
  SnacksPickerCursorLine = { bg = darker_black },

  SnacksTitle = { fg = one_bg, bg = red },
  SnacksPicker = { bg = one_bg },
  SnacksPickerDir = { fg = grey_fg2 },
  SnacksPickerPathHidden = { fg = grey_fg },
  SnacksPickerMatch = { link = "IncSearch" },
  -- Nvim-DAP-UI {{{2
  DapUIBreakpointsCurrentLine = { bold = true, fg = white },
  DapUIBreakpointsDisabledLine = { link = "Comment" },
  DapUIBreakpointsInfo = { fg = blue },
  DapUIBreakpointsPath = { link = "Directory" },
  DapUIDecoration = { fg = line },
  DapUIFloatBorder = { fg = line },
  DapUILineNumber = { fg = teal },
  DapUIModifiedValue = { bold = true, fg = teal },
  DapUIPlayPause = { fg = green },
  DapUIRestart = { fg = green },
  DapUIScope = { link = "Special" },
  DapUISource = { fg = red },
  DapUIStepBack = { fg = teal },
  DapUIStepInto = { fg = teal },
  DapUIStepOut = { fg = teal },
  DapUIStepOver = { fg = teal },
  DapUIStop = { fg = red },
  DapUIStoppedThread = { fg = teal },
  DapUIThread = { fg = white },
  DapUIType = { link = "Type" },
  DapUIUnavailable = { fg = grey },
  DapUIWatchesEmpty = { fg = red },
  DapUIWatchesError = { fg = red },
  DapUIWatchesValue = { fg = white },
  -- }}}
  -- lazy.nvim {{{2
  LazyProgressTodo = { fg = grey },
  -- }}}

  -- Statusline (Detailed Blocks) {{{2
  StatusLineGitAdded = { bg = statusline, fg = green },
  StatusLineGitChanged = { bg = statusline, fg = yellow },
  StatusLineGitRemoved = { bg = statusline, fg = red },
  StatusLineGitBranch = { bg = statusline, fg = grey_fg },

  StatusLineLspWarn = { fg = yellow, bg = statusline }, -- Blended Amber
  StatusLineLspINFO = { fg = cyan, bg = statusline },
  StatusLineLspError = { fg = red, bg = statusline },
  StatusLineLspHint = { fg = teal, bg = statusline },

  StatusLineGitAdd = { fg = green, bg = statusline },
  StatusLineGitChange = { fg = one_bg3, bg = statusline },
  StatusLineGitDelete = { fg = red, bg = statusline },

  StatusLineFilename = { fg = white, bg = statusline },
  StatusLineDimmed = { fg = grey_fg, bg = statusline }, -- 40% White blend equivalent

  StatusLineFileError = { fg = red, bg = statusline },
  StatusLineFileModified = { fg = green, bg = statusline },
  StatusLineFileMacro = { fg = green, bg = statusline },
  -- }}}2
  -- Header blocks (e.g., Mode or File Info)
  StatusLineHeader = { bg = one_bg3, fg = white },
  StatusLineHeaderModified = { bg = green, fg = black },
  StatusLineHeaderError = { bg = red, fg = black },
  -- }}}
  -- The spinner glows in Rosewater while working
  LspSpinner = { fg = maroon, bg = statusline, bold = true },

  -- The idle checkmark stays a subtle green
  LspReady = { fg = green, bg = statusline },
  -- NamuPreview = { link = "CursorLine" },
}

local hl = require "utils.hl"
local get_hlgroup = hl.get_hlgroup
-- local persist = hl.persist
-- local set_hlgroups = hl.set_hlgroups
local bg = get_hlgroup("Normal").bg
local bg_alt = get_hlgroup("Visual").bg
local snack_green = get_hlgroup("String").fg
local snack_red = get_hlgroup("ErrorMsg").fg
local bg_dark = get_hlgroup("NormalFloat").bg
-- return a table of highlights for snacks.picker based on
-- colors retrieved from highlight groups

local chad_hl = {
  SnacksPickerBorder = { fg = bg_alt, bg = bg },
  SnacksPicker = { bg = bg },
  SnacksPickerPreviewBorder = { fg = bg, bg = bg },
  SnacksPickerPreview = { bg = bg },
  SnacksPickerPreviewTitle = { fg = bg, bg = snack_green },
  SnacksPickerBoxBorder = { fg = bg, bg = bg },
  SnacksPickerInputBorder = { fg = bg, bg = bg },
  SnacksPickerInputSearch = { fg = snack_red, bg = bg },
  SnacksPickerListBorder = { fg = bg, bg = bg_dark },
  SnacksPickerList = { bg = bg_dark },
  SnacksPickerListTitle = { fg = bg, bg = bg_dark },
  SnacksPickerCursorLine = { bg = bg },

  SnacksPickerDir = { link = "Directory" },
  SnacksPickerPathHidden = { link = "Comment" },
  SnacksPickerMatch = { fg = snack_red },
}

-- hlgroups = require("utils.general").extend_tbl(hlgroups, chad_hl)

-- Highlight group overrides {{{1
if vim.go.bg == "light" then
  hlgroups.CursorLine = { bg = one_bg }
  hlgroups.DiagnosticSignWarn = { fg = yellow }
  hlgroups.DiagnosticUnderlineWarn = { sp = yellow, undercurl = true }
  hlgroups.DiagnosticVirtualTextWarn = { bg = one_bg2, fg = yellow }
  hlgroups.DiagnosticWarn = { fg = yellow }
  hlgroups.IncSearch = { bg = yellow, fg = black, bold = true }
  hlgroups.Keyword = { fg = red }
  hlgroups.ModeMsg = { fg = red, bold = true }
  hlgroups.Pmenu = { bg = black, fg = white }
  hlgroups.PmenuSbar = { bg = one_bg }
  hlgroups.PmenuSel = { bg = white, fg = black }
  hlgroups.PmenuThumb = { bg = one_bg3 }
  hlgroups.Search = { bg = one_bg2 }
  hlgroups.StatusLine = { bg = black }
  hlgroups.StatusLineGitAdded = { bg = black, fg = green }
  hlgroups.StatusLineGitChanged = { bg = black, fg = yellow }
  hlgroups.StatusLineGitRemoved = { bg = black, fg = red }
  hlgroups.StatusLineGitBranch = { bg = black, fg = grey_fg }
  hlgroups.StatusLineHeader = { bg = white, fg = black }
  hlgroups.StatusLineHeaderModified = { bg = red, fg = black }
  hlgroups.Visual = { bg = one_bg2 }
  hlgroups.WinBar = { bg = black, fg = white }
  hlgroups.WinBarNC = { bg = one_bg, fg = grey_fg2 }
  hlgroups["@variable.parameter"] = { link = "Identifier" }
end
-- }}}
-- Set highlight groups {{{1
for name, attr in pairs(hlgroups) do
  attr.ctermbg = attr.bg and attr.bg[2]
  attr.ctermfg = attr.fg and attr.fg[2]
  attr.bg = attr.bg and attr.bg[1]
  attr.fg = attr.fg and attr.fg[1]
  attr.sp = attr.sp and attr.sp[1]
  vim.api.nvim_set_hl(0, name, attr)
end
-- }}}
