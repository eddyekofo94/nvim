#!/usr/bin/env python3
"""Generate colorscheme files from palette tables."""

import os
import re


def generate_colorscheme(palette_name: str, palette: dict) -> str:
    """Generate a complete colorscheme from a palette dictionary."""

    def get_color(*keys, default="#808080"):
        for key in keys:
            if key in palette:
                val = palette[key]
                if isinstance(val, list):
                    return val[0] if val else default
                return val
        return default

    colors = {
        "green": get_color("green", "base0B", "#98c379"),
        "vibrant_green": get_color("vibrant_green", "green", "#98c379"),
        "red": get_color("red", "base08", "#ff6b6b"),
        "yellow": get_color("yellow", "base0A", "#e5c07b"),
        "baby_pink": get_color("baby_pink", "pink", "#ff79c6"),
        "blue": get_color("blue", "base0D", "#61afef"),
        "one_bg3": get_color("one_bg3", "base04", "#555555"),
        "maroon": get_color("maroon", "#eba0ac"),
        "teal": get_color("teal", "#14b8a6"),
        "one_bg2": get_color("one_bg2", "base03", "#444444"),
        "black": get_color("black", "base00", "#1e1e1e"),
        "black2": get_color("black2", "base01", "#282828"),
        "darker_black": get_color("darker_black", "#191919"),
        "one_bg": get_color("one_bg", "base02", "#333333"),
        "sapphire": get_color("sapphire", "#74c7ec"),
        "white": get_color("white", "base05", "#d4d4d4"),
        "light_grey": get_color("light_grey", "#606060"),
        "grey_fg2": get_color("grey_fg2", "base07", "#777777"),
        "grey_fg": get_color("grey_fg", "base06", "#999999"),
        "grey": get_color("grey", "#666666"),
        "orange": get_color("orange", "base09", "#d19a66"),
        "pink": get_color("pink", "#ff79c6"),
        "purple": get_color("purple", "base0E", "#c678dd"),
        "cyan": get_color("cyan", "base0C", "#56b6c2"),
        "lavender": get_color("lavender", "#b4befe"),
        "line": get_color("line", "#3e3e3e"),
        "statusline": get_color("statusline_bg", "lightbg", get_color("black2")),
        "nord_blue": get_color("nord_blue", "#88c0d0"),
        "rosewater": get_color("rosewater", "#f5e0dc"),
        "sun": get_color("sun", "#ffe9b6"),
        "folder_bg": get_color("folder_bg", "blue", "#61afef"),
        "dark_purple": get_color("dark_purple", "#c7a0dc"),
        "nord_blue": get_color("nord_blue", "#88c0d0"),
        "rosewater": get_color("rosewater", "#f5e0dc"),
    }

    var_decls = []
    for name, hex in sorted(colors.items()):
        var_decls.append(f"local {name} = {{ '{hex}' }}")

    terminal_colors = f"""vim.g.terminal_color_0  = black2[1]
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
vim.g.terminal_color_15 = white[1]"""

    hlgroups = []
    hl = hlgroups.append

    # UI
    hl("  ColorColumn = { bg = one_bg2 },")
    hl("  Conceal = { bold = true, fg = grey },")
    hl("  CurSearch = { link = 'IncSearch' },")
    hl("  Cursor = { bg = white, fg = black },")
    hl("  CursorColumn = { link = 'CursorLine' },")
    hl("  CursorIM = { link = 'Cursor' },")
    hl("  CursorLine = { bg = black2 },")
    hl("  CursorLineNr = { fg = white, bold = true },")
    hl("  DebugPC = { bg = one_bg2 },")
    hl("  DiffAdd = { fg = green },")
    hl("  DiffAdded = { fg = green },")
    hl("  DiffChange = { fg = sun },")
    hl("  DiffChanged = { fg = yellow },")
    hl("  DiffDelete = { fg = red },")
    hl("  DiffDeleted = { fg = red },")
    hl("  DiffNewFile = { fg = green },")
    hl("  DiffOldFile = { fg = red },")
    hl("  DiffRemoved = { fg = red },")
    hl("  DiffText = { bg = one_bg3 },")
    hl("  FloatBorder = { bg = darker_black, fg = line },")
    hl("  FloatFooter = { bg = darker_black, fg = grey_fg },")
    hl("  FloatTitle = { fg = white },")
    hl("  FoldColumn = { fg = grey_fg },")
    hl("  Folded = { bg = one_bg, fg = grey_fg2 },")
    hl("  Ignore = { link = 'NonText' },")
    hl("  IncSearch = { bg = orange, fg = black },")
    hl("  LineNr = { fg = grey_fg },")
    hl("  MatchParen = { bg = one_bg3 },")
    hl("  ModeMsg = { fg = red, bold = true },")
    hl("  MoreMsg = { fg = blue },")
    hl("  MsgArea = { fg = white },")
    hl("  MsgSeparator = { bg = black },")
    hl("  NonText = { fg = one_bg3 },")
    hl("  Normal = { bg = black, fg = white },")
    hl("  NormalFloat = { bg = darker_black, fg = white },")
    hl("  NormalNC = { link = 'Normal' },")
    hl("  PmenuExtra = { fg = grey_fg },")
    hl("  PmenuSbar = { bg = black2 },")
    hl("  PmenuSel = { bg = black2, fg = 'NONE', bold = true },")
    hl("  PmenuThumb = { bg = grey },")
    hl("  Question = { link = 'MoreMsg' },")
    hl("  QuickFixLine = { bg = one_bg },")
    hl("  SignColumn = { fg = grey },")
    hl("  SpellBad = { underdashed = true, sp = red },")
    hl("  SpellCap = { underdashed = true, sp = yellow },")
    hl("  SpellLocal = { underdashed = true, sp = blue },")
    hl("  SpellRare = { underdashed = true, sp = purple },")
    hl("  Substitute = { bg = red, fg = black },")
    hl("  TabLine = { link = 'StatusLineNC' },")
    hl("  TabLineFill = { link = 'Normal' },")
    hl("  TabLineSel = { link = 'StatusLine' },")
    hl("  TermCursor = { fg = black, bg = red },")
    hl("  Title = { bold = true, fg = blue },")
    hl("  Underlined = { fg = teal, underline = true },")
    hl("  VertSplit = { link = 'WinSeparator' },")
    hl("  Visual = { bg = one_bg3 },")
    hl("  VisualNOS = { link = 'Visual' },")
    hl("  Whitespace = { fg = one_bg3 },")
    hl("  WildMenu = { link = 'Pmenu' },")
    hl("  WinBar = { bg = black, fg = white },")
    hl("  WinBarNC = { bg = black, fg = grey_fg },")
    hl("  WinSeparator = { fg = line },")
    hl("  lCursor = { link = 'Cursor' },")

    # Syntax
    hl("  Boolean = { fg = sun, italic = true, bold = true },")
    hl("  Character = { link = 'String' },")
    hl("  Comment = { fg = grey_fg, italic = true },")
    hl("  Constant = { fg = orange, italic = true },")
    hl("  Delimiter = { fg = orange },")
    hl("  Error = { fg = red },")
    hl("  Float = { link = 'Number' },")
    hl("  Function = { fg = purple },")
    hl("  Number = { fg = orange },")
    hl("  SpecialKey = { fg = grey },")
    hl("  String = { fg = green },")
    hl("  Todo = { fg = black, bg = blue, bold = true },")
    hl("  Type = { fg = yellow },")
    hl("  PreProc = { fg = sapphire },")
    hl("  Include = { fg = dark_purple },")
    hl("  Define = { fg = purple },")
    hl("  Conditional = { fg = maroon },")
    hl("  Repeat = { fg = red },")
    hl("  Typedef = { fg = red },")
    hl("  Exception = { fg = red },")
    hl("  Statement = { fg = lavender },")
    hl("  Keyword = { fg = pink, italic = true },")
    hl("  Enum = { link = 'Macro' },")
    hl("  Method = { link = 'Function' },")
    hl("  Special = { fg = sun },")
    hl("  SpecialChar = { fg = orange },")
    hl("  WarningMsg = { link = 'DiagnosticWarn' },")
    hl("  ErrorMsg = { fg = red },")
    hl("  EndOfBuffer = { fg = black },")
    hl("  Search = { fg = black, bg = teal },")
    hl("  Identifier = { fg = lavender },")
    hl("  Operator = { fg = pink },")
    hl("  Pmenu = { link = 'NormalFloat' },")
    hl("  Macro = { fg = lavender },")
    hl("  Directory = { fg = folder_bg },")

    # Treesitter TS groups
    ts = [
        ("TSAnnotation", "purple"),
        ("TSAttribute", "purple"),
        ("TSBoolean", "sun"),
        ("TSComment", "grey_fg"),
        ("TSConditional", "red"),
        ("TSConstBuiltin", "dark_purple"),
        ("TSConstant", "white"),
        ("TSConstructor", "green"),
        ("TSField", "blue"),
        ("TSFloat", "purple"),
        ("TSFuncBuiltin", "orange"),
        ("TSFuncMacro", "green"),
        ("TSFunction", "purple"),
        ("TSFunctionCall", "red"),
        ("TSInclude", "red"),
        ("TSKeyword", "pink"),
        ("TSKeywordFunction", "purple"),
        ("TSKeywordOperator", "maroon"),
        ("TSKeywordReturn", "purple"),
        ("TSLabel", "blue"),
        ("TSMath", "blue"),
        ("TSMethod", "purple"),
        ("TSMethodCall", "orange"),
        ("TSNamespace", "purple"),
        ("TSNone", "white"),
        ("TSNumber", "orange"),
        ("TSOperator", "pink"),
        ("TSParameter", "baby_pink"),
        ("TSParameterReference", "white"),
        ("TSProperty", "lavender"),
        ("TSPunctBracket", "lavender"),
        ("TSRepeat", "red"),
        ("TSStorageClass", "blue"),
        ("TSString", "green"),
        ("TSStringEscape", "green"),
        ("TSStringRegex", "green"),
        ("TSSymbol", "nord_blue"),
        ("TSTag", "sun"),
        ("TSTagAttribute", "green"),
        ("TSText", "green"),
        ("TSType", "yellow"),
        ("TSTypeBuiltin", "maroon"),
        ("TSTypeDefinition", "pink"),
        ("TSURI", "vibrant_green"),
        ("TSVariable", "white"),
        ("TSVariableBuiltin", "pink"),
    ]
    for name, color in ts:
        hl(f"  {name} = {{ fg = {color} }},")

    # @ treesitter groups
    at = [
        ("@string", "green"),
        ("@keyword", "pink"),
        ("@function", "purple"),
        ("@type", "yellow"),
        ("@number", "orange"),
        ("@operator", "pink"),
        ("@variable", "white"),
        ("@text", "green"),
        ("@annotation", "purple"),
        ("@attribute", "purple"),
        ("@constant", "orange"),
        ("@constructor", "green"),
        ("@field", "blue"),
        ("@include", "dark_purple"),
        ("@method", "purple"),
        ("@namespace", "blue"),
        ("@parameter", "teal"),
        ("@property", "lavender"),
        ("@statement", "lavender"),
        ("@comment", "grey_fg"),
        ("@boolean", "sun"),
        ("@conditional", "red"),
        ("@repeat", "red"),
        ("@label", "blue"),
        ("@float", "purple"),
        ("@function.builtin", "orange"),
        ("@function.call", "purple"),
        ("@method.call", "orange"),
        ("@keyword.function", "purple"),
        ("@keyword.return", "purple"),
        ("@keyword.operator", "maroon"),
        ("@keyword.import", "dark_purple"),
        ("@keyword.exception", "red"),
        ("@type.builtin", "maroon"),
        ("@variable.parameter", "teal"),
        ("@variable.member", "nord_blue"),
        ("@variable.builtin", "pink"),
        ("@constant.builtin", "dark_purple"),
        ("@module", "baby_pink"),
        ("@function.method", "red"),
        ("@markup.link", "cyan"),
        ("@markup.raw", "lavender"),
        ("@markup.heading", "blue"),
        ("@markup.list", "sun"),
        ("@markup.quote", "black2"),
        ("@diff.plus", "green"),
        ("@diff.minus", "red"),
        ("@diff.delta", "sun"),
        ("@keyword.repeat", "purple"),
        ("@variable.member.key", "nord_blue"),
        ("@number.float", "pink"),
        ("@keyword.storage", "yellow"),
        ("@keyword.directive", "yellow"),
        ("@string.regexp", "pink"),
    ]
    for name, color in at:
        if name == "@markup.link.url":
            hl(f"  ['{name}'] = {{ fg = {color}, italic = true, underline = true }},")
        elif name == "@markup.italic":
            hl(f"  ['{name}'] = {{ italic = true }},")
        elif name == "@markup.strong":
            hl(f"  ['{name}'] = {{ bold = true }},")
        elif name == "@function.builtin.bash":
            hl(f"  ['{name}'] = {{ fg = {color}, italic = true }},")
        else:
            hl(f"  ['{name}'] = {{ fg = {color} }},")

    # Comment groups with backgrounds
    hl("  ['@comment.todo'] = { fg = black, bg = white, bold = true },")
    hl("  ['@comment.warning'] = { fg = black2, bg = yellow },")
    hl("  ['@comment.danger'] = { fg = black2, bg = red },")

    # Markup
    hl("  ['@markup.italic'] = { italic = true },")
    hl("  ['@markup.strong'] = { bold = true },")
    hl(
        "  ['@markup.link.url'] = { fg = vibrant_green, italic = true, underline = true },"
    )

    # @ treesitter groups that link to TS groups
    at_link = [
        ("@preproc", "TSPreProc"),
        ("@none", "TSNone"),
        ("@punctuation.bracket", "TSPunctBracket"),
        ("@punctuation.delimiter", "TSPunctDelimiter"),
        ("@punctuation.special", "TSPunctSpecial"),
        ("@storageclass", "TSStorageClass"),
        ("@storageclass.lifetime", "TSStorageClassLifetime"),
        ("@strike", "TSStrike"),
        ("@string.escape", "TSStringEscape"),
        ("@string.regex", "TSStringRegex"),
        ("@string.special", "TSStringSpecial"),
        ("@symbol", "TSSymbol"),
        ("@tag", "TSTag"),
        ("@tag.attribute", "TSTagAttribute"),
        ("@tag.delimiter", "TSTagDelimiter"),
        ("@text.danger", "TSDanger"),
        ("@text.diff.add", "DiffAdded"),
        ("@text.diff.delete", "DiffRemoved"),
        ("@text.emphasis", "TSEmphasis"),
        ("@text.environment", "TSEnvironment"),
        ("@text.environment.name", "TSEnvironmentName"),
        ("@text.literal", "TSLiteral"),
        ("@text.math", "TSMath"),
        ("@text.note", "TSNote"),
        ("@text.reference", "TSTextReference"),
        ("@text.strike", "TSStrike"),
        ("@text.strong", "TSStrong"),
        ("@text.title", "TSTitle"),
        ("@text.todo", "TSTodo"),
        ("@text.todo.checked", "Todo"),
        ("@text.todo.unchecked", "Ignore"),
        ("@text.underline", "TSUnderline"),
        ("@text.uri", "TSURI"),
        ("@text.warning", "TSWarning"),
        ("@todo", "TSTodo"),
        ("@type.definition", "TSTypeDefinition"),
        ("@type.qualifier", "TSTypeQualifier"),
        ("@uri", "TSURI"),
    ]
    for name, target in at_link:
        hl(f"  ['{name}'] = {{ link = '{target}' }},")

    # Diagnostic
    hl("  DiagnosticError = { fg = red },")
    hl("  DiagnosticHint = { fg = teal },")
    hl("  DiagnosticInfo = { fg = cyan },")
    hl("  DiagnosticOk = { fg = green },")
    hl("  DiagnosticWarn = { fg = yellow },")
    hl("  DiagnosticSignError = { fg = red },")
    hl("  DiagnosticSignHint = { fg = teal },")
    hl("  DiagnosticSignInfo = { fg = cyan },")
    hl("  DiagnosticSignWarn = { fg = yellow },")
    hl("  DiagnosticUnderlineError = { sp = red, undercurl = true },")
    hl("  DiagnosticUnderlineHint = { sp = teal, undercurl = true },")
    hl("  DiagnosticUnderlineInfo = { sp = cyan, undercurl = true },")
    hl("  DiagnosticUnderlineWarn = { sp = yellow, undercurl = true },")
    hl("  DiagnosticVirtualTextError = { bg = black2, fg = red },")
    hl("  DiagnosticVirtualTextHint = { bg = black2, fg = teal },")
    hl("  DiagnosticVirtualTextInfo = { bg = black2, fg = cyan },")
    hl("  DiagnosticVirtualTextWarn = { bg = black2, fg = yellow },")
    hl("  DiagnosticUnnecessary = { fg = grey, sp = teal, undercurl = true },")
    hl("  LspCodeLens = { fg = grey },")
    hl("  LspReferenceText = { bg = one_bg3 },")
    hl("  LspSignatureActiveParameter = { fg = sun },")

    # LSP Semantic Tokens
    hl("  ['@lsp.mod.readonly'] = { link = 'Constant' },")
    hl("  ['@lsp.mod.typeHint'] = { link = 'Type' },")
    hl("  ['@lsp.type.builtinConstant'] = { link = '@constant.builtin' },")
    hl("  ['@lsp.type.comment'] = { fg = 'NONE' },")
    hl("  ['@lsp.type.macro'] = { fg = pink },")
    hl("  ['@lsp.type.magicFunction'] = { link = '@function.builtin' },")
    hl("  ['@lsp.type.method'] = { link = '@function.method' },")
    hl("  ['@lsp.type.namespace'] = { link = '@module' },")
    hl("  ['@lsp.type.parameter'] = { link = '@variable.parameter' },")
    hl("  ['@lsp.type.selfParameter'] = { link = '@variable.builtin' },")
    hl("  ['@lsp.type.variable'] = { fg = 'NONE' },")
    hl("  ['@lsp.typemod.function.builtin'] = { link = '@function.builtin' },")
    hl("  ['@lsp.typemod.function.defaultLibrary'] = { link = '@function.builtin' },")
    hl("  ['@lsp.typemod.function.readonly'] = { bold = true, fg = blue },")
    hl("  ['@lsp.typemod.keyword.documentation'] = { link = 'Special' },")
    hl("  ['@lsp.typemod.method.defaultLibrary'] = { link = '@function.builtin' },")
    hl("  ['@lsp.typemod.operator.controlFlow'] = { link = '@keyword.exception' },")
    hl("  ['@lsp.typemod.operator.injected'] = { link = 'Operator' },")
    hl("  ['@lsp.typemod.string.injected'] = { link = 'String' },")
    hl("  ['@lsp.typemod.variable.defaultLibrary'] = { link = '@variable.builtin' },")
    hl("  ['@lsp.typemod.variable.injected'] = { link = '@variable' },")
    hl("  ['@lsp.typemod.variable.static'] = { link = 'Constant' },")

    # Go LSP & Tree-sitter
    hl("  ['@lsp.property.go'] = { link = 'Function' },")
    hl("  ['@lsp.type.go'] = { link = 'Keyword' },")
    hl("  ['@lsp.type.keyword.go'] = { link = 'Keyword' },")
    hl("  ['@lsp.type.builtin.go'] = { fg = pink },")
    hl("  ['@lsp.variable.member.go'] = { fg = blue },")
    hl("  ['@type.go'] = { fg = purple, bold = true },")
    hl("  ['@keyword.function.go'] = { fg = purple, italic = true },")
    hl("  ['@variable.member.go'] = { fg = nord_blue },")
    hl("  ['@variable.parameter.go'] = { fg = teal },")
    hl("  ['@function.method.go'] = { fg = red },")
    hl("  ['@lsp.type.interface.go'] = { fg = yellow, italic = true },")
    hl("  ['@lsp.type.struct.go'] = { fg = purple },")
    hl("  ['@lsp.type.variable.go'] = { fg = white },")
    hl("  ['@lsp.type.parameter.go'] = { fg = pink },")
    hl("  ['@lsp.type.function.go'] = { fg = blue },")
    hl("  ['@lsp.type.method.go'] = { fg = blue },")
    hl("  ['@lsp.type.namespace.go'] = { fg = orange },")
    hl("  ['@lsp.mod.readonly.go'] = { fg = orange, bold = true },")
    hl("  ['@lsp.mod.format.go'] = { fg = rosewater },")
    hl("  ['@function.builtin.go'] = { fg = orange, bold = true },")

    # LSP UI
    hl("  LspInfoBorder = { link = 'FloatBorder' },")
    hl("  LspReferenceRead = { link = 'LspReferenceText' },")
    hl("  LspReferenceWrite = { bg = one_bg3 },")

    # Filetype
    hl("  gitHash = { fg = grey },")

    # Sh/Bash
    hl("  bashSpecialVariables = { link = 'Constant' },")
    hl("  shAstQuote = { link = 'Constant' },")
    hl("  shCaseEsac = { link = 'Operator' },")
    hl("  shDeref = { link = 'Special' },")
    hl("  shDerefSimple = { link = 'shDerefVar' },")
    hl("  shDerefVar = { link = 'Constant' },")
    hl("  shNoQuote = { link = 'shAstQuote' },")
    hl("  shQuote = { link = 'String' },")
    hl("  shTestOpr = { link = 'Operator' },")

    # HTML
    hl("  htmlBold = { bold = true },")
    hl("  htmlBoldItalic = { bold = true, italic = true },")
    hl("  htmlH1 = { fg = red, bold = true },")
    hl("  htmlH2 = { fg = red, bold = true },")
    hl("  htmlH3 = { fg = red, bold = true },")
    hl("  htmlH4 = { fg = red, bold = true },")
    hl("  htmlH5 = { fg = red, bold = true },")
    hl("  htmlH6 = { fg = red, bold = true },")
    hl("  htmlItalic = { italic = true },")
    hl("  htmlLink = { fg = blue, underline = true },")
    hl("  htmlSpecialChar = { link = 'SpecialChar' },")
    hl("  htmlSpecialTagName = { fg = purple },")
    hl("  htmlString = { link = 'String' },")
    hl("  htmlTagName = { link = 'Tag' },")
    hl("  htmlTitle = { link = 'Title' },")
    hl("  markdownBold = { bold = true },")
    hl("  markdownCode = { fg = green },")
    hl("  markdownListMarker = { fg = sun },")
    hl("  healthError = { fg = red },")
    hl("  healthSuccess = { fg = green },")
    hl("  healthWarning = { fg = yellow },")

    # Markdown
    hl("  markdownBoldItalic = { bold = true, italic = true },")
    hl("  markdownCodeBlock = { fg = green },")
    hl("  markdownError = { fg = 'NONE' },")
    hl("  markdownEscape = { fg = 'NONE' },")
    hl("  markdownH1 = { link = 'htmlH1' },")
    hl("  markdownH2 = { link = 'htmlH2' },")
    hl("  markdownH3 = { link = 'htmlH3' },")
    hl("  markdownH4 = { link = 'htmlH4' },")
    hl("  markdownH5 = { link = 'htmlH5' },")
    hl("  markdownH6 = { link = 'htmlH6' },")

    # Help & Quickfix
    hl("  helpHeader = { link = 'Title' },")
    hl("  helpSectionDelim = { link = 'Title' },")
    hl("  qfFileName = { link = 'Directory' },")
    hl("  qfLineNr = { link = 'LineNr' },")

    # Plugins
    hl("  GitSignsAdd = { link = 'DiffAdd' },")
    hl("  GitSignsChange = { link = 'DiffChange' },")
    hl("  GitSignsDelete = { link = 'DiffDelete' },")
    hl("  TelescopeBorder = { bg = black2, fg = line },")
    hl("  TelescopeNormal = { bg = black2, fg = white },")
    hl("  TelescopeMatching = { fg = red, bold = true },")
    hl("  TelescopeSelection = { link = 'Visual' },")
    hl("  TelescopeTitle = { bg = teal, fg = black },")
    hl("  SnacksPicker = { bg = one_bg },")
    hl("  DapUIPlayPause = { fg = green },")
    hl("  DapUIStepInto = { fg = teal },")
    hl("  DapUIStop = { fg = red },")
    hl("  DapUIWatchesValue = { fg = white },")

    hl("  fugitiveHash = { link = gitHash },")
    hl("  fugitiveHeader = { link = Title },")
    hl("  fugitiveHeading = { link = Title },")
    hl("  fugitiveStagedHeading = { fg = green, bold = true },")
    hl("  fugitiveStagedModifier = { fg = green },")
    hl("  fugitiveUnStagedHeading = { fg = yellow, bold = true },")
    hl("  fugitiveUnstagedModifier = { fg = yellow },")
    hl("  fugitiveUntrackedHeading = { fg = teal, bold = true },")
    hl("  fugitiveUntrackedModifier = { fg = teal },")

    hl("  ColorfulWinSep = { fg = red },")
    hl("  HighlightURL = { fg = teal, underline = true },")

    # Statusline
    hl("  StatusLine = { bg = statusline, fg = white },")
    hl("  StatusLineNC = { bg = black2, fg = grey_fg },")
    hl("  StatusLineSeparator = { fg = black2, bg = statusline },")
    hl("  StatusLineGitAdded = { bg = statusline, fg = green },")
    hl("  StatusLineGitChanged = { bg = statusline, fg = yellow },")
    hl("  StatusLineGitRemoved = { bg = statusline, fg = red },")
    hl("  StatusLineGitBranch = { bg = statusline, fg = grey_fg },")
    hl("  StatusLineLspError = { bg = statusline, fg = red },")
    hl("  StatusLineLspWarn = { bg = statusline, fg = yellow },")
    hl("  StatusLineLspINFO = { bg = statusline, fg = cyan },")
    hl("  StatusLineLspHint = { bg = statusline, fg = teal },")
    hl("  StatusLineFilename = { bg = statusline, fg = white },")
    hl("  StatusLineHeader = { bg = one_bg3, fg = white },")
    hl("  StatusLineDimmed = { bg = statusline, fg = grey_fg },")
    hl("  StatusLineHeaderModified = { bg = green, fg = black },")
    hl("  LspReady = { fg = green, bg = statusline },")
    hl("  StatusLineFileError = { fg = red, bg = statusline },")
    hl("  StatusLineFileModified = { fg = green, bg = statusline },")
    hl("  StatusLineFileMacro = { fg = green, bg = statusline },")
    hl("  LspSpinner = { fg = maroon, bg = statusline, bold = true },")

    return f"""-- Name:         {palette_name}
-- Description:  Generated from palette
-- Last Updated: {os.popen('date "+%a %d %b %Y %I:%M %p"').read().strip()}

vim.cmd.hi('clear')
vim.g.colors_name = '{palette_name}'

-- stylua: ignore start
{chr(10).join(var_decls)}
-- stylua: ignore end

-- Terminal colors
-- stylua: ignore start
{terminal_colors}
-- stylua: ignore end

-- Highlight groups
local hlgroups = {{
{chr(10).join(hlgroups)}
}}

-- Set highlight groups
for name, attr in pairs(hlgroups) do
  attr.ctermbg = attr.bg and attr.bg[2]
  attr.ctermfg = attr.fg and attr.fg[2]
  attr.bg = attr.bg and attr.bg[1]
  attr.fg = attr.fg and attr.fg[1]
  attr.sp = attr.sp and attr.sp[1]
  vim.api.nvim_set_hl(0, name, attr)
end
"""


def load_palette(path: str) -> dict:
    with open(path, "r") as f:
        content = f.read()
    match = re.search(r"return\s*\{(.+)\}", content, re.DOTALL)
    if not match:
        raise ValueError(f"Could not find return statement in {path}")
    palette_text = match.group(1)
    palette = {}
    for line in palette_text.split("\n"):
        line = line.strip().rstrip(",")
        if not line or line.startswith("--"):
            continue
        key_match = re.match(r"(\w+)\s*=\s*(?:\{([^}]+)\}|'([^']+)')", line)
        if key_match:
            key = key_match.group(1)
            if key_match.group(2):
                value = key_match.group(2)
                hex_match = re.search(r"'([^']+)'", value)
                if hex_match:
                    palette[key] = hex_match.group(1)
            elif key_match.group(3):
                palette[key] = key_match.group(3)
    return palette


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Generate colorschemes from palettes")
    parser.add_argument("palette", nargs="?", help="Palette name")
    parser.add_argument("--all", action="store_true", help="Generate all palettes")
    parser.add_argument("--output", "-o", default="colors", help="Output directory")
    args = parser.parse_args()

    config_dir = os.path.expanduser("~/.config/nvim")
    palettes_dir = os.path.join(config_dir, "palettes")
    output_dir = os.path.join(config_dir, args.output)
    os.makedirs(output_dir, exist_ok=True)

    if args.all:
        for filename in os.listdir(palettes_dir):
            if filename.endswith(".lua"):
                palette_name = filename[:-4]
                palette_path = os.path.join(palettes_dir, filename)
                print(f"Generating {palette_name}...")
                try:
                    palette = load_palette(palette_path)
                    colorscheme = generate_colorscheme(palette_name, palette)
                    output_path = os.path.join(output_dir, f"{palette_name}.lua")
                    with open(output_path, "w") as f:
                        f.write(colorscheme)
                except Exception as e:
                    print(f"  ERROR: {e}")
        print("\nDone!")

    elif args.palette:
        palette = load_palette(os.path.join(palettes_dir, f"{args.palette}.lua"))
        colorscheme = generate_colorscheme(args.palette, palette)
        output_path = os.path.join(output_dir, f"{args.palette}.lua")
        with open(output_path, "w") as f:
            f.write(colorscheme)
        print(f"Generated: {output_path}")
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
