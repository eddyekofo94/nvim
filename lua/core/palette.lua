local M = {}

local palettes_dir = vim.fn.stdpath('config') .. '/palettes'
local colors_dir = vim.fn.stdpath('config') .. '/colors'

function M.setup()
  M.generate_colorscheme_wrappers()

  vim.keymap.set('n', '<leader>tp', function()
    M.switch_next()
  end, { desc = 'Switch to next palette' })
end

function M.generate_colorscheme_wrappers()
  local wrapper_template = [[
-- Auto-generated wrapper for palette: %s
-- Do not edit manually
vim.g.palette_name = '%s'
vim.cmd.colorscheme('palette')
]]

  local palettes = M.list()
  for _, palette_name in ipairs(palettes) do
    local wrapper_path = colors_dir .. '/' .. palette_name .. '.lua'
    local existing = vim.uv.fs_stat(wrapper_path)
    if not existing then
      local file = io.open(wrapper_path, 'w')
      if file then
        file:write(string.format(wrapper_template, palette_name, palette_name))
        file:close()
      end
    end
  end
end

function M.list()
  local palettes = {}
  for file in vim.fs.dir(palettes_dir) do
    local name = file:match('^(.+)%.lua$')
    if name then
      table.insert(palettes, name)
    end
  end
  return palettes
end

function M.load(palette_name)
  local palette_path = palettes_dir .. '/' .. palette_name .. '.lua'
  local palette = dofile(palette_path)
  if not palette then
    vim.notify(
      '[theme] Failed to load palette: ' .. palette_name,
      vim.log.levels.ERROR
    )
    return
  end

  vim.g.palette_name = palette_name
  vim.cmd.colorscheme('palette')

  local get_hl = vim.api.nvim_get_hl

  local function to_hex(color)
    if type(color) == 'string' then
      return color
    elseif type(color) == 'number' then
      return string.format('#%06x', color)
    end
    return nil
  end

  local function hex_to_rgb(hex)
    if type(hex) == 'number' then
      hex = string.format('#%06x', hex)
    end
    hex = to_hex(hex) or hex
    hex = hex:gsub('#', '')
    return {
      tonumber(hex:sub(1, 2), 16),
      tonumber(hex:sub(3, 4), 16),
      tonumber(hex:sub(5, 6), 16),
    }
  end

  local function blend_colors(c1, c2, alpha)
    alpha = alpha or 0.5
    local rgb1 = hex_to_rgb(c1)
    local rgb2 = hex_to_rgb(c2)
    local r = math.floor(rgb1[1] * (1 - alpha) + rgb2[1] * alpha)
    local g = math.floor(rgb1[2] * (1 - alpha) + rgb2[2] * alpha)
    local b = math.floor(rgb1[3] * (1 - alpha) + rgb2[3] * alpha)
    return string.format('#%02x%02x%02x', r, g, b)
  end

  local function apply_palette_color(hl_name, palette_key, fallback_hex)
    if not palette[palette_key] then
      return
    end
    local color = palette[palette_key]
    local ok, hl = pcall(get_hl, 0, { name = hl_name, link = false })
    if ok and hl then
      local fg = hl.fg or fallback_hex
      local bg_color = hl.bg
      if fg then
        local new_fg = blend_colors(fg, color, 0.5)
        vim.api.nvim_set_hl(
          0,
          hl_name,
          vim.tbl_extend('force', hl, { fg = new_fg })
        )
      end
    end
  end

  local color_mappings = {
    Conceal = 'grey',
    CurSearch = 'black',
    Cursor = 'black',
    CursorIM = 'black',
    CursorLineNr = 'white',
    DiffAdd = 'green',
    DiffAdded = 'green',
    DiffChange = 'sun',
    DiffChanged = 'yellow',
    DiffDelete = 'red',
    DiffDeleted = 'red',
    DiffNewFile = 'green',
    DiffOldFile = 'red',
    DiffRemoved = 'red',
    DiffText = 'one_bg3',
    FloatBorder = 'line',
    FloatFooter = 'grey_fg',
    FloatTitle = 'white',
    FoldColumn = 'grey_fg',
    Folded = 'grey_fg2',
    Ignore = 'one_bg3',
    IncSearch = 'black',
    LineNr = 'grey_fg',
    ModeMsg = 'red',
    MoreMsg = 'blue',
    MsgArea = 'white',
    NonText = 'one_bg3',
    Normal = 'white',
    NormalFloat = 'white',
    NormalNC = 'white',
    PmenuExtra = 'grey_fg',
    Question = 'blue',
    SignColumn = 'grey',
    Substitute = 'black',
    TabLine = 'grey_fg',
    TabLineFill = 'white',
    TabLineSel = 'white',
    TermCursor = 'black',
    Title = 'blue',
    Underlined = 'teal',
    VertSplit = 'line',
    Whitespace = 'one_bg3',
    WildMenu = 'white',
    WinBar = 'white',
    WinBarNC = 'grey_fg',
    WinSeparator = 'line',
    lCursor = 'black',
    Boolean = 'sun',
    Character = 'green',
    Constant = 'orange',
    Delimiter = 'orange',
    Error = 'red',
    Float = 'orange',
    Function = 'purple',
    Number = 'orange',
    SpecialKey = 'grey',
    String = 'green',
    Todo = 'black',
    Type = 'yellow',
    PreProc = 'sapphire',
    PreCondit = 'purple',
    Include = 'dark_purple',
    Define = 'purple',
    Conditional = 'maroon',
    Repeat = 'red',
    Typedef = 'red',
    Exception = 'red',
    Statement = 'lavender',
    Keyword = 'pink',
    Comment = 'grey_fg',
    Enum = 'lavender',
    Method = 'purple',
    Special = 'sun',
    SpecialChar = 'orange',
    WarningMsg = 'yellow',
    ErrorMsg = 'red',
    InfoMsg = 'cyan',
    HintMsg = 'teal',
    HighlightURL = 'teal',
    EndOfBuffer = 'black',
    Search = 'black',
    Identifier = 'lavender',
    Operator = 'pink',
    Pmenu = 'white',
    Macro = 'lavender',
    Directory = 'folder_bg',
    FocusedWindow = 'white',
    UnfocusedWindow = 'grey',
    TroublePreview = 'red',
    TelescopeResultsTitle = 'black',
    WhichKeyDesc = 'pink',
    WhichKeyGroup = 'blue',
    FlashLabel = 'green',
    FlashMatch = 'purple',
    FlashCurrent = 'sun',
    FlashPrompt = 'white',
    FlashBackdrop = 'light_grey',
    TSAnnotation = 'purple',
    TSAttribute = 'purple',
    TSBoolean = 'sun',
    TSCharacter = 'green',
    TSCharacterSpecial = 'orange',
    TSComment = 'grey_fg',
    TSConditional = 'red',
    TSConstBuiltin = 'dark_purple',
    TSConstMacro = 'purple',
    TSConstant = 'white',
    TSConstructor = 'green',
    TSDefine = 'purple',
    TSEnvironment = 'lavender',
    TSEnvironmentName = 'yellow',
    TSError = 'red',
    TSException = 'red',
    TSField = 'blue',
    TSFloat = 'purple',
    TSFuncBuiltin = 'orange',
    TSFuncMacro = 'green',
    TSFunction = 'purple',
    TSFunctionCall = 'red',
    TSInclude = 'red',
    TSKeyword = 'pink',
    TSKeywordFunction = 'purple',
    TSKeywordOperator = 'maroon',
    TSKeywordReturn = 'purple',
    TSLabel = 'blue',
    TSLiteral = 'green',
    TSMath = 'blue',
    TSMethod = 'purple',
    TSMethodCall = 'orange',
    TSNamespace = 'purple',
    TSNone = 'white',
    TSNumber = 'orange',
    TSOperator = 'pink',
    TSParameter = 'baby_pink',
    TSParameterReference = 'white',
    TSPreProc = 'sapphire',
    TSProperty = 'lavender',
    TSPunctBracket = 'lavender',
    TSPunctDelimiter = 'orange',
    TSPunctSpecial = 'blue',
    TSRepeat = 'red',
    TSStorageClass = 'blue',
    TSStorageClassLifetime = 'blue',
    TSStrike = 'grey_fg',
    TSString = 'green',
    TSStringEscape = 'green',
    TSStringRegex = 'green',
    TSStringSpecial = 'orange',
    TSSymbol = 'nord_blue',
    TSTag = 'sun',
    TSTagAttribute = 'green',
    TSTagDelimiter = 'green',
    TSText = 'green',
    TSTextReference = 'orange',
    TSTitle = 'blue',
    TSTodo = 'black',
    TSType = 'yellow',
    TSTypeBuiltin = 'maroon',
    TSTypeDefinition = 'pink',
    TSTypeQualifier = 'sun',
    TSURI = 'vibrant_green',
    TSVariable = 'white',
    TSVariableBuiltin = 'pink',
    StatusLine = 'white',
    StatusLineNC = 'grey_fg',
    StatusLineSeparator = 'black2',
    LspCodeLens = 'grey',
    LspInfoBorder = 'line',
    LspSignatureActiveParameter = 'sun',
    DiagnosticError = 'red',
    DiagnosticHint = 'teal',
    DiagnosticInfo = 'cyan',
    DiagnosticOk = 'green',
    DiagnosticWarn = 'yellow',
    DiagnosticSignError = 'red',
    DiagnosticSignHint = 'teal',
    DiagnosticSignInfo = 'blue',
    DiagnosticSignWarn = 'yellow',
    DiagnosticVirtualTextError = 'red',
    DiagnosticVirtualTextHint = 'teal',
    DiagnosticVirtualTextInfo = 'blue',
    DiagnosticVirtualTextWarn = 'yellow',
    DiagnosticUnnecessary = 'grey',
    gitHash = 'grey',
    bashSpecialVariables = 'orange',
    shAstQuote = 'orange',
    shCaseEsac = 'pink',
    shDeref = 'sun',
    shDerefSimple = 'orange',
    shDerefVar = 'orange',
    shNoQuote = 'orange',
    shQuote = 'green',
    shTestOpr = 'pink',
    htmlH1 = 'red',
    htmlH2 = 'red',
    htmlH3 = 'red',
    htmlH4 = 'red',
    htmlH5 = 'red',
    htmlH6 = 'red',
    htmlBold = 'blue',
    htmlItalic = 'blue',
    htmlLink = 'blue',
    htmlSpecialTagName = 'purple',
    htmlString = 'green',
    markdownBold = 'blue',
    markdownCode = 'green',
    markdownH1 = 'red',
    markdownH2 = 'red',
    markdownH3 = 'red',
    markdownH4 = 'red',
    markdownH5 = 'red',
    markdownH6 = 'red',
    markdownListMarker = 'sun',
    healthError = 'red',
    healthSuccess = 'green',
    healthWarning = 'yellow',
    helpHeader = 'blue',
    helpSectionDelim = 'blue',
    qfFileName = 'folder_bg',
    qfLineNr = 'grey_fg',
    GitSignsAdd = 'green',
    GitSignsChange = 'yellow',
    GitSignsDelete = 'red',
    TelescopeBorder = 'line',
    TelescopeNormal = 'white',
    TelescopeMatching = 'red',
    TelescopePromptBorder = 'line',
    TelescopePromptNormal = 'white',
    TelescopeSelection = 'one_bg3',
    TelescopeTitle = 'black',
    PickerBorder = 'darker_black',
    PickerNormal = 'white',
    PickerListCursorLine = 'black2',
    SnacksPickerBorder = 'darker_black',
    SnacksPickerTitle = 'darker_black',
    SnacksPickerListCursorLine = 'black2',
    SnacksPickerBufType = 'red',
    SnacksPickerPreviewBorder = 'darker_black',
    SnacksPickerPreview = 'darker_black',
    SnacksPickerPreviewTitle = 'darker_black',
    SnacksPickerBoxBorder = 'darker_black',
    SnacksPickerBox = 'white',
    SnacksPickerInputBorder = 'darker_black',
    SnacksPickerInputSearch = 'red',
    SnacksPickerInput = 'darker_black',
    SnacksPickerList = 'darker_black',
    SnacksPickerListTitle = 'darker_black',
    SnacksPickerCursorLine = 'darker_black',
    SnacksTitle = 'one_bg',
    SnacksPicker = 'one_bg',
    SnacksPickerDir = 'grey_fg2',
    SnacksPickerPathHidden = 'grey_fg',
    SnacksPickerMatch = 'orange',
    DapUIBreakpointsCurrentLine = 'white',
    DapUIBreakpointsInfo = 'blue',
    DapUIDecoration = 'line',
    DapUIFloatBorder = 'line',
    DapUILineNumber = 'teal',
    DapUIModifiedValue = 'teal',
    DapUIPlayPause = 'green',
    DapUIRestart = 'green',
    DapUISource = 'red',
    DapUIStepBack = 'teal',
    DapUIStepInto = 'teal',
    DapUIStepOut = 'teal',
    DapUIStepOver = 'teal',
    DapUIStop = 'red',
    DapUIStoppedThread = 'teal',
    DapUIThread = 'white',
    DapUIType = 'yellow',
    DapUIWatchesValue = 'white',
    LazyProgressTodo = 'grey',
    StatusLineGitAdded = 'green',
    StatusLineGitChanged = 'yellow',
    StatusLineGitRemoved = 'red',
    StatusLineGitBranch = 'grey_fg',
    StatusLineLspWarn = 'yellow',
    StatusLineLspINFO = 'cyan',
    StatusLineLspError = 'red',
    StatusLineLspHint = 'teal',
    StatusLineFileError = 'red',
    StatusLineFileModified = 'green',
    StatusLineFileMacro = 'green',
    StatusLineFilename = 'white',
    StatusLineDimmed = 'grey_fg',
    StatusLineHeader = 'white',
    StatusLineHeaderModified = 'green',
    StatusLineHeaderError = 'red',
    LspSpinner = 'maroon',
    LspReady = 'green',
    CursorLine = 'black2',
    Visual = 'one_bg3',
    CursorColumn = 'black2',
    MatchParen = 'one_bg3',
    PmenuSel = 'black2',
    PmenuSbar = 'black2',
    PmenuThumb = 'grey',
    ColorColumn = 'one_bg2',
    DebugPC = 'one_bg2',
    WinBarNC = 'black',
    FloatTitle = 'white',
    NormalFloat = 'darker_black',
    TabLineSel = 'white',
    TabLine = 'grey_fg',
    TabLineFill = 'white',
    ['@string'] = 'green',
    ['@keyword'] = 'pink',
    ['@function'] = 'purple',
    ['@type'] = 'yellow',
    ['@number'] = 'orange',
    ['@operator'] = 'pink',
    ['@variable'] = 'white',
    ['@text'] = 'green',
    ['@annotation'] = 'purple',
    ['@attribute'] = 'purple',
    ['@constant'] = 'orange',
    ['@constructor'] = 'green',
    ['@field'] = 'blue',
    ['@include'] = 'dark_purple',
    ['@method'] = 'purple',
    ['@namespace'] = 'blue',
    ['@parameter'] = 'teal',
    ['@property'] = 'lavender',
    ['@statement'] = 'lavender',
    ['@comment'] = 'grey_fg',
    ['@comment.documentation'] = 'grey_fg',
    ['@conditional'] = 'red',
    ['@constant.builtin'] = 'dark_purple',
    ['@constant.macro'] = 'purple',
    ['@function.builtin'] = 'orange',
    ['@function.call'] = 'purple',
    ['@function.macro'] = 'green',
    ['@function.call'] = 'purple',
    ['@keyword.function'] = 'purple',
    ['@keyword.conditional'] = 'maroon',
    ['@keyword.operator'] = 'maroon',
    ['@keyword.return'] = 'purple',
    ['@keyword.import'] = 'dark_purple',
    ['@keyword.storage'] = 'yellow',
    ['@keyword.directive'] = 'yellow',
    ['@keyword.exception'] = 'red',
    ['@keyword.repeat'] = 'purple',
    ['@variable.member'] = 'nord_blue',
    ['@variable.member.key'] = 'nord_blue',
    ['@variable.parameter'] = 'teal',
    ['@module'] = 'baby_pink',
    ['@function.method'] = 'red',
    ['@markup.link'] = 'cyan',
    ['@markup.raw'] = 'lavender',
    ['@markup.link.url'] = 'vibrant_green',
    ['@markup.heading'] = 'blue',
    ['@markup.list'] = 'sun',
    ['@markup.quote'] = 'black2',
    ['@markup.italic'] = 'white',
    ['@markup.strong'] = 'white',
    ['@comment.todo'] = 'black',
    ['@comment.warning'] = 'yellow',
    ['@comment.danger'] = 'red',
    ['@diff.plus'] = 'green',
    ['@diff.minus'] = 'red',
    ['@diff.delta'] = 'sun',
    ['@string.regexp'] = 'pink',
    ['@number.float'] = 'pink',
    ['@function.call.lua'] = 'nord_blue',
    ['@variable.member.lua'] = 'blue',
    ['@constructor.lua'] = 'rosewater',
    ['@function.lua'] = 'purple',
    ['@functional.call.lua'] = 'nord_blue',
    ['@lsp.type.variable.lua'] = 'white',
    ['@lsp.type.parameter.lua'] = 'sun',
    ['@lsp.type.function.lua'] = 'sapphire',
    ['@lsp.type.property.lua'] = 'lavender',
    ['@lsp.type.method.lua'] = 'blue',
    ['@lsp.typemod.variable.global.lua'] = 'rosewater',
    ['@variable.parameter.lua'] = 'sun',
    ['@lsp.variable.lua'] = 'teal',
    ['@function.builtin.bash'] = 'purple',
    ['@variable.parameter.bash'] = 'white',
    ['@lsp.mod.readonly'] = 'orange',
    ['@lsp.mod.typeHint'] = 'yellow',
    ['@lsp.type.builtinConstant'] = 'dark_purple',
    ['@lsp.type.comment'] = 'grey',
    ['@lsp.type.macro'] = 'pink',
    ['@lsp.type.magicFunction'] = 'orange',
    ['@lsp.type.method'] = 'red',
    ['@lsp.type.namespace'] = 'baby_pink',
    ['@lsp.type.parameter'] = 'teal',
    ['@lsp.type.selfParameter'] = 'pink',
    ['@lsp.type.variable'] = 'white',
    ['@lsp.typemod.function.builtin'] = 'orange',
    ['@lsp.typemod.function.defaultLibrary'] = 'orange',
    ['@lsp.typemod.function.readonly'] = 'blue',
    ['@lsp.typemod.keyword.documentation'] = 'sun',
    ['@lsp.typemod.method.defaultLibrary'] = 'orange',
    ['@lsp.typemod.operator.controlFlow'] = 'red',
    ['@lsp.typemod.operator.injected'] = 'pink',
    ['@lsp.typemod.string.injected'] = 'green',
    ['@lsp.typemod.variable.defaultLibrary'] = 'pink',
    ['@lsp.typemod.variable.injected'] = 'white',
    ['@lsp.typemod.variable.static'] = 'orange',
    ['@lsp.property.go'] = 'purple',
    ['@lsp.type.go'] = 'pink',
    ['@lsp.type.keyword.go'] = 'pink',
    ['@lsp.type.builtin.go'] = 'pink',
    ['@lsp.variable.member.go'] = 'blue',
    ['@type.go'] = 'purple',
    ['@keyword.function.go'] = 'purple',
    ['@variable.member.go'] = 'nord_blue',
    ['@variable.parameter.go'] = 'teal',
    ['@function.method.go'] = 'red',
    ['@lsp.type.interface.go'] = 'yellow',
    ['@lsp.type.struct.go'] = 'purple',
    ['@lsp.type.variable.go'] = 'white',
    ['@lsp.type.parameter.go'] = 'pink',
    ['@lsp.type.function.go'] = 'blue',
    ['@lsp.type.method.go'] = 'blue',
    ['@lsp.type.namespace.go'] = 'orange',
    ['@lsp.mod.readonly.go'] = 'orange',
    ['@lsp.mod.format.go'] = 'rosewater',
    ['@function.builtin.go'] = 'orange',
  }

  for hl_name, palette_key in pairs(color_mappings) do
    if palette[palette_key] then
      local ok, hl = pcall(get_hl, 0, { name = hl_name, link = false })
      if ok and hl then
        local new_hl = vim.deepcopy(hl)
        local palette_color = palette[palette_key]
        if type(palette_color) == 'table' then
          palette_color = palette_color[1]
        end
        if hl.fg then
          local fg_hex = to_hex(hl.fg)
          if fg_hex then
            new_hl.fg = blend_colors(fg_hex, palette_color, 0.7)
          end
        end
        if hl.bg then
          local bg_hex = to_hex(hl.bg)
          if bg_hex then
            new_hl.bg = blend_colors(bg_hex, palette_color, 0.3)
          end
        end
        vim.api.nvim_set_hl(0, hl_name, new_hl)
      end
    end
  end

  vim.notify('[theme] Loaded: ' .. palette_name, vim.log.levels.INFO)
end

function M.switch_next()
  local palettes = M.list()
  if #palettes == 0 then
    vim.notify('[theme] No palettes found', vim.log.levels.WARN)
    return
  end

  local current = vim.g.palette_name or palettes[1]
  local current_idx = vim.iter(palettes):find(function(_, v)
    return v == current
  end) or 1
  local next_idx = (current_idx % #palettes) + 1
  M.load(palettes[next_idx])
end

vim.api.nvim_create_user_command('Theme', function(args)
  if args.args == '' then
    vim.notify(
      'Available palettes: ' .. table.concat(M.list(), ', '),
      vim.log.levels.INFO
    )
    return
  end
  M.load(args.args)
end, {
  nargs = '?',
  complete = function()
    return M.list()
  end,
})

return M
