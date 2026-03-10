local M = {}

local palettes_dir = vim.fn.stdpath('config') .. '/palettes'

function M.setup()
  vim.keymap.set('n', '<leader>tp', function()
    M.switch_next()
  end, { desc = 'Switch to next palette' })
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
  vim.cmd.colorscheme('catppuccin')

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
    Normal = 'black',
    CursorLine = 'black2',
    Visual = 'one_bg3',
    CursorLineNr = 'white',
    Comment = 'grey_fg',
    String = 'green',
    Keyword = 'pink',
    Function = 'purple',
    Type = 'yellow',
    Number = 'orange',
    Operator = 'pink',
    Delimiter = 'orange',
    Constant = 'orange',
    Special = 'sun',
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
    DiffAdd = 'green',
    DiffChange = 'sun',
    DiffDelete = 'red',
    DiffText = 'one_bg3',
    Error = 'red',
    Warning = 'yellow',
    Hint = 'teal',
    Info = 'cyan',
    DiagnosticError = 'red',
    DiagnosticWarn = 'yellow',
    DiagnosticHint = 'teal',
    DiagnosticInfo = 'cyan',
    Pmenu = 'one_bg',
    PmenuSel = 'black2',
    PmenuSbar = 'black2',
    PmenuThumb = 'grey',
    StatusLine = 'statusline_bg',
    StatusLineNC = 'black2',
    WinBar = 'black',
    WinBarNC = 'black',
    FloatBorder = 'line',
    NormalFloat = 'darker_black',
    Folded = 'one_bg',
    LineNr = 'grey_fg',
    CursorColumn = 'black2',
    TabLine = 'statusline_bg',
    TabLineSel = 'statusline_bg',
    TabLineFill = 'black',
    SignColumn = 'grey',
    Title = 'blue',
    VertSplit = 'line',
    Whitespace = 'one_bg3',
    MatchParen = 'one_bg3',
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
