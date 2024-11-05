-- local colors = require("base46").get_theme_tb "base_30"
local hl = require "utils.hl"
local get_hl = hl.get_hl
local nv_bg = { "black", "darker_black", 30 }
local diff_bg = { "red", "black", 30 }

return {
  BaseDark00 = { fg = "base00" },
  BaseDark01 = { fg = "base01" },
  BaseDark02 = { fg = "base02" },
  BaseDarkGrey03 = { fg = "base03" },
  BaseDarkGrey04 = { fg = "base04" },
  BaseLight05 = { fg = "base05" },
  BaseLight06 = { fg = "base06" },
  BaseWhite07 = { fg = "base07" },
  BaseRed08 = { fg = "base08" },
  BaseOrange09 = { fg = "base09" },
  BaseYellow0A = { fg = "base0A" },
  BaseGreen0B = { fg = "base0B" },
  BaseTeal0C = { fg = "base0C" },
  BaseBlue0D = { fg = "base0D" },
  BasePurple0E = { fg = "base0E" },
  BasePink08 = { fg = "base0F" },

  Rosewater = { fg = "#f5e0dc" },
  Flamingo = { fg = "#f2cdcd" },
  Maroon = { fg = "#eba0ac" },
  sapphire = { fg = "#74c7ec" },

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

  -- Mini
  -- MiniFilesBorder = {},
  MiniIconsAzure = { fg = "nord_blue" },
  MiniIconsBlue = { fg = "blue" },
  MiniIconsCyan = { fg = "cyan" },
  MiniIconsGreen = { fg = "green" },
  MiniIconsGrey = { fg = "grey" },
  MiniIconsOrange = { fg = "orange" },
  MiniIconsPurple = { fg = "purple" },
  MiniIconsRed = { fg = "red" },
  MiniIconsYellow = { fg = "yellow" },

  CmpItemMenu = { fg = "lavender" },
  CmpItemAbbrDeprecated = { fg = "light_grey", strikethrough = true },
  CmpItemAbbrDeprecatedDefault = { link = "CmpItemAbbrDeprecated" },

  BlinkCmpMenuBorder = { link = "FloatBorder" },

  CursorLineNr = { fg = "white" },

  GitSignsChange = { fg = "sun" },

  LspInfoBorder = { link = "FloatBorder" },
  DiagnosticDeprecated = { fg = { "red", "black", 30 }, strikethrough = true },

  NormalFloat = { bg = "darker_black" },
  NormalNC = { link = "Normal" },
  Pmenu = { bg = "black2", fg = "" },
  PmenuSel = { link = "Visual" },
  NvimSeparator = { link = "Debug" },
  EndOfBuffer = { fg = "black" }, -- INFO: buffer
  FloatBorder = { bg = "NONE", fg = "line" },
  HighlightedYankRegion = {
    reverse = true,
  },

  -- OverLength
  OverLength = { fg = "NONE", bg = "#840000" },

  -- Flash.nvim
  FlashLabel = { fg = "green" },
  FlashMatch = { fg = "purple" },
  FlashCurrent = { fg = "sun" },
  FlashPrompt = { link = "NormalFloat" },
  FlashBackdrop = { fg = "light_grey" },

  TelescopePromptBorder = { bg = "line", fg = "black2" },
  TelescopePromptCounter = { fg = "grey" },
  TelescopePromptNormal = { bg = "line" },
  TelescopePromptPrefix = { bg = "line" },
  TelescopePromptTitle = { fg = "line", bg = "black2" },
  TelescopeResultsBorder = { bg = nv_bg, fg = nv_bg },
  TelescopeResultsNormal = { bg = nv_bg },
  TelescopeResultsTitle = { fg = nv_bg, bg = nv_bg },
  TelescopeSelection = { fg = "lavender", bg = "black2" },
  TelescopePreviewBorder = { bg = "darker_black", fg = "darker_black" },
  TelescopePreviewNormal = { bg = "darker_black" },
  TelescopePreviewTitle = { fg = "darker_black", bg = "darker_black" },
  TelescopeSelectionCaret = { fg = "pink" },

  WhichKeyFloat = { bg = "black2" },

  NeogitDiffDelete = {
    fg = { "red", "white", 10 },
    bg = { "red", "black", 82 },
  },
  NeogitDiffDeleteHighlight = {
    fg = "red",
    bg = { "red", "black", 88 },
  },
  NeogitDiffDeleteCursor = { fg = "red", bg = "NONE" },
  NeogitChangeDeleted = {
    fg = "red",
    bold = true,
  },
  NeogitStagedchanges = { fg = "green", bg = { "green", "black", 86 }, bold = true },

  NotifyINFOIcon = { fg = "cyan" },
  NotifyINFOTitle = { link = "NotifyINFOIcon" },

  IblIndent = { fg = "line" },
  IblScope = { fg = "light_grey" },

  Number = { link = "BaseYellow0A" },
  Boolean = { link = "BaseOrange09" },
  Float = { link = "Number" },

  PreProc = { fg = "purple" },
  PreCondit = { fg = "purple" },
  Include = { fg = "purple" },
  Define = { fg = "purple" },
  Conditional = { fg = "red" },
  Repeat = { fg = "red" },
  Keyword = { fg = "red" },
  Typedef = { fg = "red" },
  Exception = { fg = "red" },
  Statement = { fg = "red" },

  StorageClass = { fg = "sun" },
  Tag = { fg = "cayn" },
  Label = { fg = "sun" },
  Structure = { fg = "sun" },
  Operator = { fg = "sun" },
  Title = { fg = "sun" },
  Special = { fg = "yellow" },
  SpecialChar = { fg = "yellow" },
  Type = { fg = "yellow", bold = true },
  Function = { fg = "dark_purple", bold = true },
  Delimiter = { fg = "grey_fg" },
  Macro = { fg = "teal" },

  ["@markup.heading"] = { fg = "blue", bold = true }, -- titles like: # Example
  ["@markup.heading.1.markdown"] = { link = "rainbow1" },
  ["@markup.heading.2.markdown"] = { link = "rainbow2" },
  ["@markup.heading.3.markdown"] = { link = "rainbow3" },
  ["@markup.heading.4.markdown"] = { link = "rainbow4" },
  ["@markup.heading.5.markdown"] = { link = "rainbow5" },
  ["@markup.heading.6.markdown"] = { link = "rainbow6" },

  ["@markup.math"] = { fg = "blue" }, -- math environments (e.g. `$ ... $` in LaTeX)
  ["@markup.quote"] = { fg = "teal", bold = true }, -- block quotes
  ["@markup.environment"] = { fg = "pink" }, -- text environments of markup languages
  ["@markup.environment.name"] = { fg = "blue" }, -- text indicating the type of an environment

  ["@markup.link"] = { link = "Tag" }, -- text references, footnotes, citations, etc.
  ["@markup.link.label"] = { link = "Label" }, -- link, reference descriptions
  ["@markup.link.url"] = { fg = "cyan", italic = true, underline = true }, -- urls, links and emails

  ["@markup.list"] = { link = "Special" },
  ["@markup.list.checked"] = { fg = "green" }, -- todo notes
  ["@markup.list.unchecked"] = { fg = "grey_fg2" }, -- todo notes

  -- rainbow
  rainbow1 = { fg = "red" },
  rainbow2 = { fg = "orange" },
  rainbow3 = { fg = "yellow" },
  rainbow4 = { fg = "green" },
  rainbow5 = { fg = "nord_blue" },
  rainbow6 = { fg = "lavender" },

  -- StatusLine
  StatusLine = { bg = "statusline_bg" },
  StatusLineLspWarning = { fg = "yellow", bg = "statusline_bg" },
  StatusLineLspInfo = { fg = get_hl("DiagnosticInfo", "fg"), bg = "statusline_bg" },
  StatusLineLspError = { fg = get_hl("DiagnosticError", "fg"), bg = "statusline_bg" },
  StatusLineLspHint = { fg = get_hl("DiagnosticHint", "fg"), bg = "statusline_bg" },

  StatusLineGitAdd = { fg = get_hl("GitSignsAdd", "fg"), bg = "statusline_bg" },
  StatusLineGitChange = { fg = get_hl("GitSignsChange", "fg"), bg = "statusline_bg" },
  StatusLineGitDelete = { fg = get_hl("GitSignsDelete", "fg"), bg = "statusline_bg" },

  StatusLineFilename = { fg = get_hl("StatusLine", "fg"), bg = "statusline_bg" },
  StatusLineDimmed = { fg = { "statusline_bg", "white", 40 }, bg = "statusline_bg" },

  StatusLineFileError = { fg = get_hl("ErrorMsg", "fg"), bg = "statusline_bg" },
  StatusLineFileModified = { fg = "green", bg = "statusline_bg" },
  StatusLineFileMacro = { fg = "green", bg = "statusline_bg" },

  TSAnnotation = { fg = "purple" },
  TSAttribute = { fg = "purple" },
  TSBoolean = { fg = "yellow" },
  TSCharacter = { link = "teal" },
  TSCharacterSpecial = { link = "SpecialChar" },
  TSComment = { link = "Comment" },
  TSConditional = { fg = "red" },
  TSConstBuiltin = { fg = "purple" },
  TSConstMacro = { fg = "purple" },
  TSConstant = { fg = "white" },
  TSConstructor = { fg = "green" },
  TSDebug = { link = "Debug" },
  TSDefine = { link = "Define" },
  TSEnvironment = { link = "Macro" },
  TSEnvironmentName = { link = "Type" },
  TSError = { link = "Error" },
  TSException = { fg = "red" },
  TSField = { fg = "blue" },
  TSFloat = { fg = "purple" },
  TSFuncBuiltin = { fg = "green" },
  TSFuncMacro = { fg = "green" },
  TSFunction = { link = "Orange" },
  TSFunctionCall = { fg = "red" },
  TSInclude = { fg = "red" },
  TSKeyword = { link = "Maroon" },
  TSKeywordFunction = { link = "Rosewater" },
  TSKeywordOperator = { fg = "sun" },
  TSKeywordReturn = { fg = "red" },
  TSLabel = { fg = "sun" },
  TSLiteral = { link = "String" },
  TSMath = { fg = "blue" },
  TSMethod = { link = "Rosewater" },
  TSMethodCall = { fg = "green" },
  TSNamespace = { link = "Rosewater" },
  TSNone = { fg = "white" },
  TSNumber = { fg = "purple" },
  TSOperator = { fg = "sun" },
  TSParameter = { fg = "baby_pink" },
  TSParameterReference = { fg = "white" },
  TSPreProc = { link = "PreProc" },
  TSProperty = { fg = "lavender" },
  TSPunctBracket = { link = "Flamingo" },
  TSPunctDelimiter = { link = "Delimiter" },
  TSPunctSpecial = { fg = "blue" },
  TSRepeat = { fg = "red" },
  TSStorageClass = { fg = "sun" },
  TSStorageClassLifetime = { fg = "sun" },
  TSStrike = { fg = "grey_fg" },
  TSString = { link = "String" },
  TSStringEscape = { fg = "green" },
  TSStringRegex = { fg = "green" },
  TSStringSpecial = { link = "SpecialChar" },
  TSSymbol = { link = "Flaming" },
  TSTag = { fg = "sun" },
  TSTagAttribute = { fg = "green" },
  TSTagDelimiter = { fg = "green" },
  TSText = { fg = "green" },
  TSTextReference = { link = "Constant" },
  TSTitle = { link = "Title" },
  TSTodo = { link = "Todo" },
  TSType = { fg = "yellow", bold = true }, -- Parameter
  TSTypeBuiltin = { link = "Flamingo" },
  TSTypeDefinition = { fg = "pink", bold = true },
  TSTypeQualifier = { fg = "sun", bold = true },
  TSURI = { fg = "cyan" },
  -- TSVariable = { fg = "white" },
  TSVariable = { fg = "white" },
  TSVariableBuiltin = { fg = "purple" },

  ["@annotation"] = { link = "TSAnnotation" },
  ["@attribute"] = { link = "TSAttribute" },
  ["@boolean"] = { link = "TSBoolean" },
  ["@character"] = { link = "TSCharacter" },
  ["@character.special"] = { link = "TSCharacterSpecial" },
  ["@comment"] = { link = "TSComment" },
  ["@comment.documentation"] = { link = "TSComment" }, -- For comments documenting code
  ["@conceal"] = { link = "Grey" },
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
  ["@keyword.conditional"] = { link = "Maroon" },

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
  ["@text.todo.checked"] = { link = "Green" },
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
  ["@variable.member"] = { fg = "lavender" }, -- For fields.

  -- Diff
  ["@diff.plus"] = { link = "diffAdded" }, -- added text (for diff files)
  ["@diff.minus"] = { link = "diffRemoved" }, -- deleted text (for diff files)
  ["@diff.delta"] = { link = "diffChanged" }, -- deleted text (for diff files)

  ["@lsp.type.class"] = { link = "TSType" },
  ["@lsp.type.comment"] = { link = "TSComment" },
  ["@lsp.type.decorator"] = { link = "TSFunction" },
  ["@lsp.type.enum"] = { link = "TSType" },
  ["@lsp.type.enumMember"] = { link = "TSProperty" },
  ["@lsp.type.events"] = { link = "TSLabel" },
  ["@lsp.type.function"] = { link = "TSFunction" },
  ["@lsp.type.interface"] = { link = "TSType" },
  ["@lsp.type.keyword"] = { link = "TSKeyword" },
  ["@lsp.type.macro"] = { link = "TSConstMacro" },
  ["@lsp.type.method"] = { link = "TSMethod" },
  ["@lsp.type.modifier"] = { link = "TSTypeQualifier" },
  ["@lsp.type.namespace"] = { link = "TSNamespace" },
  ["@lsp.type.number"] = { link = "TSNumber" },
  ["@lsp.type.operator"] = { link = "TSOperator" },
  ["@lsp.type.parameter"] = { link = "TSParameter" },
  ["@lsp.type.property"] = { link = "TSProperty" },
  ["@lsp.type.regexp"] = { link = "TSStringRegex" },
  ["@lsp.type.string"] = { link = "TSString" },
  ["@lsp.type.struct"] = { link = "TSType" },
  ["@lsp.type.type"] = { link = "TSType" },
  ["@lsp.type.typeParameter"] = { link = "TSTypeDefinition" },
  ["@lsp.type.variable"] = { link = "Rosewater" },

  -- go
  ["@property.go"] = { fg = "yellow" },
  ["@type.go"] = { link = "Flamingo" },
  ["@type.builtin.go"] = { fg = "yellow" },
  ["@variable.member.go"] = { fg = "sun" },
  ["@variable.parameter.go"] = { fg = "red" },

  -- bash
  ["@function.builtin.bash"] = { fg = "purple", italic = true },
  --  INFO: 2024-10-14 - Lua
  -- bash
  ["@variable.parameter.bash"] = { fg = "white" }, -- INFO: chadrc

  --- zsh
  zshKSHFunction = { link = "Function" },
  zshFunction = { fg = "blue" }, -- INFO: chadrc
  zshParentheses = { fg = "lavender" }, -- INFO: chadrc
  zshBrackets = { fg = "lavender" }, -- INFO: chadrc

  -- lua
  ["@variable.member.lua"] = { fg = "blue" },
  ["@constructor.lua"] = { link = "Rosewater" },
  ["@variable.parameter.lua"] = { fg = "sun" }, -- INFO: chadrc
  ["@function.lua"] = { fg = "blue" },
  ["@lsp.type.variable.lua"] = { fg = "white" },
  ["@lsp.type.parameter.lua"] = { fg = "pink" },
  ["@lsp.type.function.lua"] = { link = "nord_blue" },
  ["@lsp.type.property.lua"] = { fg = "lavender" },
  ["@lsp.type.method.lua"] = { fg = "blue" },
  ["@lsp.typemod.variable.global.lua"] = { link = "Rosewater" },
}
