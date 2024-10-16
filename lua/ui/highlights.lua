local hl = require "utils.hl"
local general = require "utils.general"
local extend_tbl = general.extend_tbl
local sethl_groups = hl.sethl_groups
local get_hl = hl.get_hl
local get_hl_group = hl.get_hlgroup
local blend = hl.blend

local highlights = {}

local color = get_hl("Normal", "bg")
if type(color) == "number" then
  color = string.format("#%06x", color)
end
local blended = blend("LineNr", "#000")
local float = { fg = blended, bg = "NONE" }

local nvchad_base_30 = {
  White = { fg = "white" },
  Black = { fg = "black" }, -- usually your theme bg
  DarkerBlack = { fg = "darker_black" }, -- 6% darker than black
  Black2 = { fg = "black2" }, -- 6% lighter than black
  OneBg = { fg = "one_bg" }, -- 10% lighter than black
  OneBg2 = { fg = "one_bg2" }, -- 6% lighter than one_bg2
  OneBg3 = { fg = "one_bg3" }, -- 6% lighter than one_bg3
  Grey = { fg = "grey" }, -- 40% lighter than black (the % here depends so choose the perfect grey!)
  GreyFg = { fg = "grey_fg" }, -- 10% lighter than grey
  GreyFg2 = { fg = "grey_fg2" }, -- 5% lighter than grey
  LightGrey = { fg = "light_grey" },
  Red = { fg = "red" },
  BabyPink = { fg = "baby_pink" },
  Pink = { fg = "pink" },
  Line = { fg = "line" }, -- 15% lighter than black
  Green = { fg = "green" },
  VibrantGreen = { fg = "vibrant_green" },
  NordBlue = { fg = "nord_blue" },
  Blue = { fg = "blue" },
  Seablue = { fg = "seablue" },
  Yellow = { fg = "yellow" }, -- 8% lighter than yellow
  Sun = { fg = "sun" },
  Purple = { fg = "purple" },
  DarkPurple = { fg = "dark_purple" },
  Teal = { fg = "teal" },
  Orange = { fg = "orange" },
  Cyan = { fg = "cyan" },
  StatusLineBG = { fg = "statusline_bg" },
  LightBg = { fg = "lightbg" },
  PmenuBg = { fg = "pmenu_bg" },
  FolderBg = { fg = "folder_bg" },
}

local hl_groups = {
  -- UI
  -- WinSeparator = { link = "LineNr" },

  EndOfBuffer = { fg = get_hl("Normal", "bg") }, -- INFO: buffer

  OverLength = { fg = "NONE", bg = "#840000" },
  NormalFloat = { fg = "lavender", bg = "darker_black" },

  Border = { fg = "line" },

  FloatBorder = { link = "Border" },

  NvimSeparator = { link = "Debug" },
  HighlightedYankRegion = {
    reverse = true,
  },

  StatusLine = { bg = "statusline_bg" },
  StatusLineLspWarning = { fg = "yellow", bg = get_hl("StatusLine", "bg") },
  StatusLineLspInfo = { fg = get_hl("DiagnosticInfo", "fg"), bg = get_hl("StatusLine", "bg") },
  StatusLineLspError = { fg = get_hl("DiagnosticError", "fg"), bg = get_hl("StatusLine", "bg") },
  StatusLineLspHint = { fg = get_hl("DiagnosticHint", "fg"), bg = get_hl("StatusLine", "bg") },

  StatusLineGitAdd = { fg = get_hl("GitSignsAdd", "fg"), bg = get_hl("StatusLine", "bg") },
  StatusLineGitChange = { fg = get_hl("GitSignsChange", "fg"), bg = get_hl("StatusLine", "bg") },
  StatusLineGitDelete = { fg = get_hl("GitSignsDelete", "fg"), bg = get_hl("StatusLine", "bg") },

  StatusLineFilename = { fg = get_hl("StatusLine", "fg"), bg = get_hl("StatusLine", "bg") },
  StatusLineDimmed = { fg = "grey_fg", bg = "statusline_bg" },

  StatusLineFileError = { fg = get_hl("ErrorMsg", "fg"), bg = get_hl("StatusLine", "bg") },
  StatusLineFileModified = { link = "String" },

  CmpSel = { link = "Visual" },

  -- Flash.nvim
  FlashLabel = { fg = "green" },
  FlashMatch = { fg = "purple" },
  FlashCurrent = { fg = "sun" },
  FlashPrompt = { link = "NormalFloat" },
  FlashBackdrop = { fg = "light_grey" },

  -- Mini
  -- MiniFilesBorder = {},
  MiniIconsAzure = { link = "NordBlue" },
  MiniIconsBlue = { link = "Blue" },
  MiniIconsCyan = { link = "Cyan" },
  MiniIconsGreen = { link = "Green" },
  MiniIconsGrey = { link = "Grey" },
  MiniIconsOrange = { link = "Sun" },
  MiniIconsPurple = { link = "Purple" },
  MiniIconsRed = { link = "Red" },
  MiniIconsYellow = { link = "Yellow" },

  MiniStatuslineModeCommand = { fg = "orange", bold = true },
  MiniStatuslineModeInsert = { fg = "green", bold = true },
  MiniStatuslineModeNormal = { fg = "nord_blue", bold = true },
  MiniStatuslineModeOther = { fg = "teal", bold = true },
  MiniStatuslineModeReplace = { fg = "yellow", bold = true },
  MiniStatuslineModeVisual = { fg = "purple", bold = true },

  -- Navbuddy
  -- NavbuddyFile = { link = "Directory" },
  -- NavbuddyModule = { link = "Title" },
  -- NavbuddyNamespace = { link = "Structure" },
  -- NavbuddyMethod = { link = "Method" },
  -- NavbuddyProperty = { link = "Statement" },
  -- NavbuddyFunction = { link = "Function" },
  -- NavbuddyVariable = { link = "Special" },
  -- NavbuddyConstant = { link = "Constant" },
  -- NavbuddyString = { link = "String" },
  -- NavbuddyNumber = { link = "Number" },
  -- NavbuddyBoolean = { link = "Boolean" },
  -- NavbuddyKey = { link = "keyword" },
  -- NavbuddyStruct = { link = "Structure" },
  -- NavbuddyEvent = { link = "Normal" },
  -- NavbuddyOperator = { link = "Operator" },
  -- NavbuddyTypeParameter = { link = "Typedef" },
  -- -- NavbuddyCursorLineFile = { fg = "Red" },
  -- -- NavbuddyCursorLineModule = { fg = "Red" },
  -- -- NavbuddyCursorLineNamespace = { fg = "Orange" },
  -- NavbuddyPackage = { fg = "Blue" },
  -- -- NavbuddyCursorLinePackage = { link = "Method" },
  -- NavbuddyClass = { fg = "Blue" },
  -- -- NavbuddyCursorLineClass = { fg = "Blue" },
  -- -- NavbuddyCursorLineMethod = { link = "Method" },
  -- -- NavbuddyCursorLineProperty = { bg = "Orange" },
  -- NavbuddyField = { fg = "Blue" },
  -- -- NavbuddyCursorLineField = { bg = "Blue" },
  -- NavbuddyConstructor = { fg = "Blue" },
  -- -- NavbuddyCursorLineConstructor = { bg = "Blue" },
  -- NavbuddyEnum = { link = "Enum" },
  -- -- NavbuddyCursorLineEnum = { bg = "Blue" },
  -- NavbuddyInterface = { fg = "Blue" },
  -- -- NavbuddyCursorLineInterface = { bg = "Blue" },
  -- -- NavbuddyCursorLineFunction = { link = "Function" },
  -- -- NavbuddyCursorLineVariable = { bg = "Orange" },
  -- -- NavbuddyCursorLineConstant = { bg = "Orange" },
  -- -- NavbuddyCursorLineString = { bg = "Green" },
  -- -- NavbuddyCursorLineNumber = { bg = "Orange" },
  -- -- NavbuddyCursorLineBoolean = { bg = "Orange" },
  -- NavbuddyArray = { link = "Array" },
  -- -- NavbuddyCursorLineArray = { link = "Array" },
  -- NavbuddyObject = { fg = "Blue" },
  -- -- NavbuddyCursorLineObject = { bg = "Blue" },
  -- -- NavbuddyCursorLineKey = { bg = "Orange" },
  -- NavbuddyNull = { fg = "Blue" },
  -- -- NavbuddyCursorLineNull = { bg = "Blue" },
  -- NavbuddyEnumMember = { fg = "Blue" },
  -- NavbuddyCursorLineEnumMember = { bg = "lCursor" },
  -- NavbuddyCursorLineStruct = { bg = "lCursor" },
  -- NavbuddyCursorLineEvent = { bg = "lCursor" },
  -- NavbuddyCursorLineOperator = { bg = "lCursor" },
  -- NavbuddyCursorLineTypeParameter = { bg = "lCursor" },
  -- NavbuddyCursorLine = { link = "lCursor" },
  -- NavbuddyCursor = { link = "lCursor" },
  -- NavbuddyName = { link = "IncSearch" },
  -- NavbuddyScope = { link = "Visual" },
  -- NavbuddyFloatBorder = { link = "FloatBorder" },

  --   ColorColumn = { bg = c_macroBg2 },
  --   Conceal = { bold = true, fg = c_macroGray2 },
  CurSearch = { link = "IncSearch" },
  --   Cursor = { bg = c_macroFg0, fg = c_macroBg1 },
  CursorColumn = { link = "CursorLine" },
  CursorIM = { link = "Cursor" },
  --   CursorLine = { bg = c_macroBg2 },
  --   CursorLineNr = { fg = c_macroGray0, bold = true },
  --   DebugPC = { bg = c_winterRed },
  --   DiffAdd = { bg = c_winterGreen },
  --   DiffChange = { bg = c_winterBlue },
  --   DiffDelete = { fg = c_macroBg4 },
  --   DiffText = { bg = c_sumiInk6 },
  --   Directory = { fg = c_macroBlue1 },
  -- EndOfBuffer = { link = "ZenBg" }, -- INFO: buffer
  --   ErrorMsg = { fg = c_lotusRed1 },
  --   FloatBorder = { bg = c_macroBg0, fg = c_sumiInk6 },
  --   FloatFooter = { bg = c_macroBg0, fg = c_macroBg5 },
  --   FloatTitle = { bg = c_macroBg0, fg = c_macroGray2, bold = true },
  --   FoldColumn = { fg = c_macroBg5 },
  --   Folded = { bg = c_macroBg2, fg = c_lotusGray },
  -- Ignore = { link = "NonText" },
  --   IncSearch = { bg = c_carpYellow, fg = c_waveBlue0 },
  --   LineNr = { fg = c_macroBg5 },
  --   MatchParen = { bg = c_macroBg4 },
  --   ModeMsg = { fg = "Red", bold = true },
  --   MoreMsg = { fg = c_macroBlue0 },
  --   MsgArea = { fg = c_macroFg1 },
  --   MsgSeparator = { bg = c_macroBg0 },
  --   NonText = { fg = c_macroBg5 },
  --   Normal = { bg = c_macroBg1, fg = c_macroFg0 },
  --   NormalFloat = { bg = c_macroBg0, fg = c_macroFg1 },
  -- NormalNC = { link = "Normal" },
  --   Pmenu = { bg = c_macroBg3, fg = c_macroFg1 },
  --   PmenuSbar = { bg = c_macroBg4 },
  --   PmenuSel = { bg = c_macroBg4, fg = "NONE" },
  --   PmenuThumb = { bg = c_macroBg5 },
  Question = { link = "MoreMsg" },
  --   QuickFixLine = { bg = c_macroBg3 },
  --   Search = { bg = c_macroBg4 },
  --   SignColumn = { fg = c_macroGray2 },
  --   SpellBad = { underdashed = true },
  --   SpellCap = { underdashed = true },
  --   SpellLocal = { underdashed = true },
  --   SpellRare = { underdashed = true },
  --   StatusLine = { bg = c_macroBg3, fg = c_macroFg1 },
  --   StatusLineNC = { bg = c_macroBg2, fg = c_macroBg5 },
  --   Substitute = { bg = c_autumnRed, fg = c_macroFg0 },
  TabLine = { link = "StatusLineNC" },
  TabLineFill = { link = "Normal" },
  TabLineSel = { link = "StatusLine" },
  --   TermCursor = { fg = c_macroBg1, bg = "Red" },
  --   TermCursorNC = { fg = c_macroBg1, bg = c_macroAsh },
  --   Title = { bold = true, fg = c_macroBlue1 },
  --   Underlined = { fg = "Teal", underline = true },
  VertSplit = { link = "WinSeparator" },
  --   Visual = { bg = c_macroBg4 },
  VisualNOS = { link = "Visual" },
  --   WarningMsg = { fg = c_roninYellow },
  --   Whitespace = { fg = c_macroBg4 },
  WildMenu = { link = "Pmenu" },
  --   WinBar = { bg = "NONE", fg = c_macroFg1 },
  WinBarNC = { link = "WinBar" },
  --   WinSeparator = { fg = c_macroBg4 },
  lCursor = { link = "Cursor" },
  --
  --   -- Syntax
  --   Boolean = { fg = "Orange", bold = true },
  Character = { link = "String" },
  --   Comment = { fg = c_macroAsh },
  --   Constant = { fg = "Orange" },
  Delimiter = { fg = "base05" },
  --   Error = { fg = c_lotusRed1 },
  --   Exception = { fg = "Red" },
  Float = { link = "Number" },
  --   Function = { fg = c_macroBlue1 },
  Identifier = { fg = "base05" },
  --   Keyword = { fg = c_macroViolet },
  --   Number = { fg = c_macroPink },
  Operator = { fg = "pink" },
  --   PreProc = { fg = "Red" },
  --   Special = { fg = "Teal" },
  --   SpecialKey = { fg = c_macroGray2 },
  Statement = { fg = "orange" },
  -- String = { link = "MoreMsg" },
  --   Todo = { fg = c_macroBg0, bg = c_macroBlue0, bold = true },
  --   Type = { fg = c_macroAqua },
  --
  --   -- Treesitter syntax
  ["@attribute"] = { link = "Constant" },
  ["@constructor"] = { fg = "Teal" },
  ["@constructor.lua"] = { link = "Pink" },
  ["@exception"] = { bold = true, fg = "Red" },
  ["@keyword.luap"] = { link = "@string.regex" },
  -- ["@keyword.operator"] = { bold = true, fg = "Operator" },
  ["@keyword.return"] = { fg = "DarkPurple", italic = true },
  ["@namespace"] = { fg = "Orange" },
  ["@operator"] = { link = "Operator" },
  ["@string"] = { link = "String" },
  ["@character"] = { link = "String" },
  -- ["@punctuation.bracket"] = { link = "Delimiter" },
  -- ["@punctuation.delimiter"] = { link = "Delimiter" },
  -- ["@punctuation.special"] = { fg = "Teal" },
  ["@string.escape"] = { fg = "Orange" },
  ["@string.regex"] = { fg = "Orange" },
  ["@symbol"] = { link = "Normal" },
  ["@tag.attribute"] = { link = "Normal" },
  --   ["@tag.delimiter"] = { fg = c_macroGray1 },
  --   ["@text.danger"] = { bg = c_lotusRed1, fg = c_macroFg0, bold = true },
  --   ["@text.diff.add"] = { fg = c_autumnGreen },
  --   ["@text.diff.delete"] = { fg = c_autumnRed },
  --   ["@text.emphasis"] = { italic = true },
  ["@text.environment"] = { link = "Keyword" },
  ["@text.environment.name"] = { link = "String" },
  ["@text.literal"] = { link = "String" },
  --   ["@text.note"] = { bg = c_waveAqua0, fg = c_waveBlue0, bold = true },
  ["@text.quote"] = { link = "@variable.parameter" },
  -- ["@text.reference.markdown_inline"] = { link = "htmlLink" },
  ["@text.strong"] = { bold = true },
  ["@text.title"] = { link = "Function" },
  --   ["@text.title.1.markdown"] = { fg = "Red" },
  --   ["@text.title.2.markdown"] = { fg = "Red" },
  --   ["@text.title.3.markdown"] = { fg = "Red" },
  --   ["@text.title.4.markdown"] = { fg = "Red" },
  --   ["@text.title.5.markdown"] = { fg = "Red" },
  --   ["@text.title.6.markdown"] = { fg = "Red" },
  --   ["@text.title.1.marker.markdown"] = { link = "Delimiter" },
  --   ["@text.title.2.marker.markdown"] = { link = "Delimiter" },
  --   ["@text.title.3.marker.markdown"] = { link = "Delimiter" },
  --   ["@text.title.4.marker.markdown"] = { link = "Delimiter" },
  --   ["@text.title.5.marker.markdown"] = { link = "Delimiter" },
  --   ["@text.title.6.marker.markdown"] = { link = "Delimiter" },
  --   ["@text.todo.checked"] = { fg = c_macroAsh },
  --   ["@text.todo.unchecked"] = { fg = "Red" },
  --   ["@text.uri.markdown_inline"] = { link = "htmlString" },
  --   ["@text.warning"] = { bg = c_roninYellow, fg = c_waveBlue0, bold = true },
  ["@variable"] = { fg = "lavender" },
  ["@variable.builtin"] = { fg = "pink", italic = true },
  ["@variable.parameter"] = { fg = "baby_pink", italic = true },
  --
  --   -- LSP semantic
  ["@lsp.mod.readonly"] = { link = "Constant" },
  ["@lsp.mod.typeHint"] = { link = "Type" },
  ["@lsp.type.builtinConstant"] = { link = "@constant.builtin" },
  --   ["@lsp.type.comment"] = { fg = "NONE" },
  --   ["@lsp.type.macro"] = { fg = c_macroPink },
  ["@lsp.type.magicFunction"] = { link = "@function.builtin" },
  ["@lsp.type.method"] = { link = "@method" },
  ["@lsp.type.namespace"] = { link = "@namespace" },
  ["@lsp.type.parameter"] = { fg = "baby_pink" },
  ["@lsp.type.selfParameter"] = { link = "@variable.builtin" },
  ["@lsp.type.variable"] = { fg = "NONE" },
  ["@lsp.typemod.function.builtin"] = { link = "@function.builtin" },
  ["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" },
  ["@lsp.typemod.function.readonly"] = { bold = true, link = "Blue" },
  ["@lsp.typemod.keyword.documentation"] = { link = "Special" },
  ["@lsp.typemod.method.defaultLibrary"] = { link = "@function.builtin" },
  ["@lsp.typemod.operator.controlFlow"] = { link = "@exception" },
  ["@lsp.typemod.operator.injected"] = { link = "Operator" },
  ["@lsp.typemod.string.injected"] = { link = "String" },
  ["@lsp.typemod.variable.defaultLibrary"] = { link = "Special" },
  ["@lsp.typemod.variable.global"] = { link = "Constant" },
  ["@lsp.typemod.variable.injected"] = { link = "@variable.parameter" },
  ["@lsp.typemod.variable.static"] = { link = "Constant" },
  --
  --   -- LSP
  --   LspCodeLens = { fg = c_macroAsh },
  LspInfoBorder = { link = "Border" },
  LspFloatBorder = { link = "Border" },
  LspFloat = { bg = "darker_black" },

  -- LspReferenceRead = { underline = true },
  -- LspReferenceText = { underline = true },
  -- LspReferenceWrite = { underline = true },
  --   LspSignatureActiveParameter = { fg = c_roninYellow },
  --
  --   -- Diagnostic
  --   DiagnosticError = { fg = "Red" },
  --   DiagnosticHint = { fg = c_macroAqua },
  --   DiagnosticInfo = { fg = c_macroBlue1 },
  --   DiagnosticOk = { fg = c_macroGreen1 },
  --   DiagnosticWarn = { fg = c_carpYellow },
  --   DiagnosticSignError = { fg = "Red" },
  --   DiagnosticSignHint = { fg = c_macroAqua },
  --   DiagnosticSignInfo = { fg = c_macroBlue1 },
  --   DiagnosticSignWarn = { fg = c_carpYellow },
  --   DiagnosticUnderlineError = { sp = "Red", undercurl = true },
  --   DiagnosticUnderlineHint = { sp = c_macroAqua, undercurl = true },
  --   DiagnosticUnderlineInfo = { sp = c_macroBlue1, undercurl = true },
  --   DiagnosticUnderlineWarn = { sp = c_carpYellow, undercurl = true },
  --   DiagnosticVirtualTextError = { bg = c_winterRed, fg = "Red" },
  --   DiagnosticVirtualTextHint = { bg = c_winterGreen, fg = c_macroAqua },
  --   DiagnosticVirtualTextInfo = { bg = c_winterBlue, fg = c_macroBlue1 },
  --   DiagnosticVirtualTextWarn = { bg = c_winterYellow, fg = c_carpYellow },
  --
  --   -- Filetype
  --   -- Git
  --   gitHash = { fg = c_macroAsh },
  --
  --   -- Sh/Bash
  bashSpecialVariables = { link = "Constant" },
  shAstQuote = { link = "Constant" },
  shCaseEsac = { link = "Operator" },
  shDeref = { link = "Special" },
  shDerefSimple = { link = "shDerefVar" },
  shDerefVar = { link = "Constant" },
  shNoQuote = { link = "shAstQuote" },
  shQuote = { link = "String" },
  shTestOpr = { link = "Operator" },
  --
  --   -- HTML
  --   htmlBold = { bold = true },
  --   htmlBoldItalic = { bold = true, italic = true },
  --   htmlH1 = { fg = "Red", bold = true },
  --   htmlH2 = { fg = "Red", bold = true },
  --   htmlH3 = { fg = "Red", bold = true },
  --   htmlH4 = { fg = "Red", bold = true },
  --   htmlH5 = { fg = "Red", bold = true },
  --   htmlH6 = { fg = "Red", bold = true },
  --   htmlItalic = { italic = true },
  --   htmlLink = { fg = c_lotusBlue, underline = true },
  --   htmlSpecialChar = { link = "SpecialChar" },
  --   htmlSpecialTagName = { fg = c_macroViolet },
  --   htmlString = { fg = c_macroAsh },
  --   htmlTagName = { link = "Tag" },
  --   htmlTitle = { link = "Title" },
  --
  --   -- Markdown
  --   markdownBold = { bold = true },
  --   markdownBoldItalic = { bold = true, italic = true },
  --   markdownCode = { fg = c_macroGreen1 },
  --   markdownCodeBlock = { fg = c_macroGreen1 },
  --   markdownError = { link = "NONE" },
  --   markdownEscape = { fg = "NONE" },
  --   markdownH1 = { link = "htmlH1" },
  --   markdownH2 = { link = "htmlH2" },
  --   markdownH3 = { link = "htmlH3" },
  --   markdownH4 = { link = "htmlH4" },
  --   markdownH5 = { link = "htmlH5" },
  --   markdownH6 = { link = "htmlH6" },
  --   markdownListMarker = { fg = c_autumnYellow },
  --
  --   -- Checkhealth
  --   healthError = { fg = c_lotusRed0 },
  --   healthSuccess = { fg = c_springGreen },
  --   healthWarning = { fg = c_roninYellow },
  helpHeader = { link = "Title" },
  helpSectionDelim = { link = "Title" },
  --
  --   -- Qf
  qfFileName = { link = "Directory" },
  qfLineNr = { link = "Number" },

  --   -- Plugins
  --   -- fugitive
  --   DiffAdded = { fg = c_autumnGreen },
  --   DiffChanged = { fg = c_autumnYellow },
  --   DiffDeleted = { fg = c_autumnRed },
  --   DiffNewFile = { fg = c_autumnGreen },
  --   DiffOldFile = { fg = c_autumnRed },
  --   DiffRemoved = { fg = c_autumnRed },
  --   fugitiveHash = { link = "gitHash" },
  --   fugitiveHeader = { link = "Title" },
  --   fugitiveStagedModifier = { fg = c_autumnGreen },
  --   fugitiveUnstagedModifier = { fg = c_autumnYellow },
  --   fugitiveUntrackedModifier = { fg = c_macroAqua },

  --   -- nvim-dap-ui
  --   DapUIBreakpointsCurrentLine = { bold = true, fg = c_macroFg0 },
  --   DapUIBreakpointsDisabledLine = { link = "Comment" },
  --   DapUIBreakpointsInfo = { fg = c_macroBlue0 },
  --   DapUIBreakpointsPath = { link = "Directory" },
  --   DapUIDecoration = { fg = c_sumiInk6 },
  --   DapUIFloatBorder = { fg = c_sumiInk6 },
  --   DapUILineNumber = { fg = "Teal" },
  --   DapUIModifiedValue = { bold = true, fg = "Teal" },
  --   DapUIPlayPause = { fg = c_macroGreen1 },
  --   DapUIRestart = { fg = c_macroGreen1 },
  --   DapUIScope = { link = "Special" },
  --   DapUISource = { fg = "Red" },
  --   DapUIStepBack = { fg = "Teal" },
  --   DapUIStepInto = { fg = "Teal" },
  --   DapUIStepOut = { fg = "Teal" },
  --   DapUIStepOver = { fg = "Teal" },
  --   DapUIStop = { fg = c_lotusRed0 },
  --   DapUIStoppedThread = { fg = "Teal" },
  --   DapUIThread = { fg = c_macroFg0 },
  --   DapUIType = { link = "Type" },
  --   DapUIUnavailable = { fg = c_macroAsh },
  --   DapUIWatchesEmpty = { fg = c_lotusRed0 },
  --   DapUIWatchesError = { fg = c_lotusRed0 },
  --   DapUIWatchesValue = { fg = c_macroFg0 },
  --
  --   -- lazy.nvim
  --   LazyProgressTodo = { fg = c_macroBg5 },
  --
  --   -- statusline
  --   StatusLineGitAdded = { bg = c_macroBg3, fg = c_macroGreen1 },
  --   StatusLineGitChanged = { bg = c_macroBg3, fg = c_carpYellow },
  --   StatusLineGitRemoved = { bg = c_macroBg3, fg = "Red" },
  --   StatusLineHeader = { bg = c_macroBg5, fg = c_macroFg1 },
  --   StatusLineHeaderModified = { bg = "Red", fg = c_macroBg1 },
}

hl_groups = extend_tbl(hl_groups, nvchad_base_30)

local fg, bg = get_hl("Normal", "fg"), get_hl("NormalFloat", "bg")

-- local bg_alt = get_hlgroup("Visual").bg
local bg_alt = get_hl("CursorLine", "bg")
-- local green = gethl("String", "fg")
local green = get_hl("String", "fg")
-- local red = get_hlgroup("Error").fg
local red = get_hl("Error", "fg")

local nv_chad_hl = {
  TelescopeBorder = { fg = bg_alt, bg = bg },
  TelescopeNormal = { bg = bg },
  TelescopePreviewBorder = { fg = bg, bg = bg },
  TelescopePreviewNormal = { bg = bg },
  TelescopePreviewTitle = { fg = bg, bg = green },
  TelescopePromptBorder = { fg = bg_alt, bg = bg_alt },
  TelescopePromptNormal = { fg = fg, bg = bg_alt },
  TelescopePromptPrefix = { fg = red, bg = bg_alt },
  TelescopePromptTitle = { fg = bg, bg = red },
  TelescopeResultsBorder = { fg = bg, bg = bg },
  TelescopeResultsNormal = { bg = bg },
  TelescopeResultsTitle = { fg = bg, bg = bg },
}

local set_all_hl = function()
  highlights = extend_tbl(highlights, hl_groups)
  -- local colorscheme = vim.g.colors_name

  -- if not string.find(colorscheme, "catppuccin") then
  highlights = extend_tbl(hl_groups, {})
  -- end

  -- if string.find(colorscheme, "zen") then
  --   highlights = extend_tbl(highlights, {
  --     String = { fg = "#819B69", bg = "NONE" },
  --     Constant = { link = "String" },
  --   })
  -- end

  sethl_groups(highlights)
end

-- set_all_hl()
--
-- vim.api.nvim_create_autocmd("ColorScheme", {
--   group = vim.api.nvim_create_augroup("Highlights", {}),
--   callback = set_all_hl,
-- })

return hl_groups
