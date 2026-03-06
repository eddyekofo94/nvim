vim.g.has_ui = #vim.api.nvim_list_uis() > 0
vim.g.has_nf = vim.env.TERM ~= 'linux' and vim.env.NVIM_NF ~= nil

vim.opt.exrc = true
vim.opt.confirm = true
vim.opt.timeout = false
vim.opt.shortmess:append({
  I = true,
  c = true,
  W = true,
  F = true,
})
vim.opt.colorcolumn = '80'
vim.opt.cursorlineopt = 'both'
vim.opt.cursorline = true
vim.opt.termsync = false
vim.opt.helpheight = 10
vim.opt.showmode = false
vim.opt.mousemoveevent = true
vim.opt.number = true
vim.opt.ruler = true
vim.opt.pumheight = 12
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.signcolumn = 'yes:1'
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.swapfile = false

local undo_path = vim.fn.stdpath('data') .. '/undo'
if vim.fn.isdirectory(undo_path) == 0 then
  vim.fn.mkdir(undo_path, 'p')
end
vim.opt.undodir = undo_path
vim.opt.undofile = true
vim.opt.wrap = false
vim.opt.linebreak = true
vim.o.termguicolors = true
vim.g.markdown_recommened_style = 1
vim.opt.breakindent = true
vim.opt.smoothscroll = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.completeopt = 'menuone'
vim.opt.selection = 'old'
vim.opt.tabclose = 'uselast'
vim.opt.relativenumber = true
vim.opt.splitkeep = 'cursor'
vim.opt.equalalways = false
vim.opt.conceallevel = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.autowriteall = true
vim.opt.virtualedit = 'block'
vim.opt.jumpoptions = 'stack,view'
vim.opt.inccommand = 'split'
vim.opt.history = 10000
vim.opt.laststatus = 3

vim.o.grepprg = 'rg --vimgrep --no-heading --smart-case'
vim.o.grepformat = '%f:%l:%c:%m,%f:%l:%m'

vim.opt.timeoutlen = 500
vim.opt.updatetime = 300

vim.opt.sessionoptions = {
  'resize',
  'winpos',
  'winsize',
  'terminal',
  'localoptions',
  'buffers',
  'curdir',
  'tabpages',
  'winsize',
  'help',
  'globals',
  'skiprtp',
  'folds',
}

do
  vim.opt.shada = ''

  local function rshada()
    vim.opt.shada = vim.api.nvim_get_option_info2('shada', {}).default
    pcall(vim.cmd.rshada)
  end

  require('utils.load').on_events('BufReadPre', 'opt.shada', rshada)
  require('utils.load').on_events(
    'UIEnter',
    'opt.shada',
    vim.schedule_wrap(rshada)
  )
end

vim.opt.foldlevelstart = 99
vim.opt.foldtext = ''
vim.opt.foldmethod = 'indent'
vim.opt.foldopen:remove('block')

vim.opt.formatoptions:append('normc')
vim.opt.formatoptions:remove('t')

vim.opt.nrformats:append('blank')

do
  vim.opt.spellsuggest = 'best,9'
  vim.opt.spellcapcheck = ''
  vim.opt.spelllang = 'en'
  vim.opt.spelloptions = 'camel'

  require('utils.load').on_events(
    'UIEnter',
    'opt.spell',
    vim.schedule_wrap(function()
      local bufs = {}

      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if require('utils.opt').spell:was_locally_set({ win = win }) then
          goto continue
        end
        vim.api.nvim_win_call(win, function()
          vim.opt.spell = true
        end)
        bufs[vim.fn.winbufnr(win)] = true
        ::continue::
      end

      for buf, _ in pairs(bufs) do
        if require('utils.ts').is_active(buf) then
          pcall(vim.treesitter.start, buf)
        end
      end
    end)
  )
end

vim.opt.diffopt:append({
  'algorithm:histogram',
  'indent-heuristic',
  'linematch:60',
})

vim.g.opt_statuscolumn = {
  folds_open = false,
  folds_githl = false,
}

vim.opt.clipboard = vim.env.SSH_TTY and '' or 'unnamedplus'

vim.opt.quickfixtextfunc = [[v:lua.require'utils.opts'.qftf]]

function _G._qftf(args)
  local qflist = args.quickfix == 1
      and vim.fn.getqflist({ id = args.id, items = 0 }).items
    or vim.fn.getloclist(args.winid, { id = args.id, items = 0 }).items

  if vim.tbl_isempty(qflist) then
    return {}
  end

  local fname_str_cache = {}
  local lnum_str_cache = {}
  local col_str_cache = {}
  local type_str_cache = {}
  local nr_str_cache = {}

  local fname_width_cache = {}
  local lnum_width_cache = {}
  local col_width_cache = {}
  local type_width_cache = {}
  local nr_width_cache = {}

  local function _traverse(trans, max_width_allowed, str_cache, width_cache)
    max_width_allowed = max_width_allowed or math.huge
    local max_width_seen = 0
    for i, item in ipairs(qflist) do
      local str = tostring(trans(item))
      local width = vim.fn.strdisplaywidth(str)
      str_cache[i] = str
      width_cache[i] = width
      if width > max_width_seen then
        max_width_seen = width
      end
    end
    return math.min(max_width_allowed, max_width_seen)
  end

  local function _fname_trans(item)
    local bufnr = item.bufnr
    local module = item.module
    local filename = item.filename
    return module and module ~= '' and module
      or filename and filename ~= '' and filename
      or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':~:.')
  end

  local function _lnum_trans(item)
    if item.lnum == item.end_lnum or item.end_lnum == 0 then
      return item.lnum
    end
    return string.format('%s-%s', item.lnum, item.end_lnum)
  end

  local function _col_trans(item)
    if item.col == item.end_col or item.end_col == 0 then
      return item.col
    end
    return string.format('%s-%s', item.col, item.end_col)
  end

  local type_sign_map = {
    E = 'ERROR',
    W = 'WARN',
    I = 'INFO',
    N = 'HINT',
  }

  local function _type_trans(item)
    local type = (type_sign_map[item.type] or item.type):gsub('[^%g]', '')
    return type == '' and '' or ' ' .. type
  end

  local function _nr_trans(item)
    return item.nr <= 0 and '' or ' ' .. item.nr
  end

  -- stylua: ignore start
  local max_width = math.ceil(vim.go.columns / 2)
  local fname_width = _traverse(_fname_trans, max_width, fname_str_cache, fname_width_cache)
  local lnum_width = _traverse(_lnum_trans, max_width, lnum_str_cache, lnum_width_cache)
  local col_width = _traverse(_col_trans, max_width, col_str_cache, col_width_cache)
  local type_width = _traverse(_type_trans, max_width, type_str_cache, type_width_cache)
  local nr_width = _traverse(_nr_trans, max_width, nr_str_cache, nr_width_cache)
  -- stylua: ignore end

  local lines = {}
  local format_str = vim.go.termguicolors and '%s %s:%s%s%s %s'
    or '%s│%s:%s%s%s│ %s'

  local function _fill_item(idx, item)
    local fname = fname_str_cache[idx]
    local fname_cur_width = fname_width_cache[idx]

    if item.lnum == 0 and item.col == 0 and item.text == '' then
      table.insert(lines, fname)
      return
    end

    local lnum = lnum_str_cache[idx]
    local col = col_str_cache[idx]
    local type = type_str_cache[idx]
    local nr = nr_str_cache[idx]

    local lnum_cur_width = lnum_width_cache[idx]
    local col_cur_width = col_width_cache[idx]
    local type_cur_width = type_width_cache[idx]
    local nr_cur_width = nr_width_cache[idx]

    table.insert(
      lines,
      string.format(
        format_str,
        fname .. string.rep(' ', fname_width - fname_cur_width),
        string.rep(' ', lnum_width - lnum_cur_width) .. lnum,
        col .. string.rep(' ', col_width - col_cur_width),
        type .. string.rep(' ', type_width - type_cur_width),
        nr .. string.rep(' ', nr_width - nr_cur_width),
        item.text
      )
    )
  end

  for i, item in ipairs(qflist) do
    _fill_item(i, item)
  end

  return lines
end

vim.opt.backup = true
vim.opt.backupdir:remove('.')

vim.opt.list = true
vim.opt.listchars = {
  tab = '→ ',
  trail = '·',
  precedes = '«',
  extends = '»',
  eol = '↲',
  nbsp = '░',
}
vim.opt.fillchars = {
  fold = '·',
  foldsep = ' ',
  eob = ' ',
}

if vim.g.has_nf then
  vim.opt.fillchars:append({
    foldopen = '',
    foldclose = '',
    fold = ' ',
    foldsep = ' ',
    diff = '╱',
    eob = ' ',
  })
else
  vim.opt.fillchars:append({
    foldopen = 'v',
    foldclose = '>',
  })
end

vim.api.nvim_create_autocmd('UIEnter', {
  once = true,
  callback = function()
    if vim.opt.termguicolors:get() then
      vim.opt.listchars:append({ nbsp = '␣' })
      vim.opt.fillchars:append({ diff = '╱' })
    end
  end,
})

vim.cmd [[
  let &t_Cs = "\e[4:3m"
  let &t_Ce = "\e[4:0m"
]]

vim.api.nvim_set_var('t_Cs', vim.api.nvim_replace_termcodes('<Esc>[4::3m', true, true, true))
vim.api.nvim_set_var('t_Ce', vim.api.nvim_replace_termcodes('<Esc>[4::0m', true, true, true))

vim.g.netrw_banner = 0
vim.g.netrw_cursor = 5
vim.g.netrw_keepdir = 0
vim.g.netrw_keepj = ''
vim.g.netrw_list_hide = [[\(^\|\s\s\)\zs\.\S\+]]
vim.g.netrw_liststyle = 1
vim.g.netrw_localcopydircmd = 'cp -r'

vim.g.fzf_layout = {
  window = {
    width = 0.8,
    height = 0.8,
    pos = 'center',
  },
}
vim.env.FZF_DEFAULT_OPTS = (vim.env.FZF_DEFAULT_OPTS or '')
  .. ' --border=sharp --margin=0 --padding=0'

vim.g.loaded_2html_plugin = 0
vim.g.loaded_gzip = 0
vim.g.loaded_matchit = 0
vim.g.loaded_spellfile_plugin = 0
vim.g.loaded_tar = 0
vim.g.loaded_tarPlugin = 0
vim.g.loaded_tutor_mode_plugin = 0
vim.g.loaded_zip = 0
vim.g.loaded_zipPlugin = 0

vim.g.loaded_remote_plugins = 0
vim.g.loaded_python3_provider = 0

require('utils.load').on_events(
  { 'FileType', 'BufReadPre', 'BufWritePost' },
  'load_runtime',
  function()
    vim.g.loaded_python3_provider = nil
    vim.g.loaded_remote_plugins = nil
    vim.cmd.runtime('provider/python3.vim')
    vim.cmd.runtime('plugin/rplugin.vim')
  end
)

require('utils.load').on_cmds(
  'UpdateRemotePlugins',
  'load_runtime',
  function()
    vim.g.loaded_python3_provider = nil
    vim.g.loaded_remote_plugins = nil
    vim.cmd.runtime('provider/python3.vim')
    vim.cmd.runtime('plugin/rplugin.vim')
  end
)

vim.opt.gcr = {
  'c-ci-ve:blinkoff500-blinkon500-block',
  'i-ci:ver30-Cursor-blinkwait500-blinkon400-blinkoff300',
  'n-v:block-Cursor/lCursor',
  'o:hor50-Cursor/lCursor',
  'r-cr:hor20-Cursor/lCursor',
}

vim.cmd [[
  let &t_Cs = "\e[4:3m"
  let &t_Ce = "\e[4:0m"
]]
