-- Enable faster lua loader using byte-compilation
-- https://github.com/neovim/neovim/commit/2257ade3dc2daab5ee12d27807c0b3bcf103cd29
vim.loader.enable()

-- add yours here!
vim.g.mapleader = " "
vim.g.maplocalleader = " "
local o = vim.o
local g = vim.g
local opt = vim.opt
local env = vim.env

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

---Restore 'shada' option and read from shada once
---@return true
local function _rshada()
  vim.cmd.set "shada&"
  vim.cmd.rshada()
  return true
end

vim.opt.shada = ""
vim.defer_fn(_rshada, 100)
vim.api.nvim_create_autocmd("BufReadPre", { once = true, callback = _rshada })

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

vim.opt.encoding = "utf-8"

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`

-- + reg: Ctrl-v nnamedplus
-- * reg: middle click unnamed
if vim.fn.has "clipboard" == 1 then
  vim.o.clipboard = "unnamedplus,unnamed"
end

-- vim.opt.clipboard = "unnamedplus"

vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy "+",
    ["*"] = require("vim.ui.clipboard.osc52").copy "*",
  },
  paste = {
    ["+"] = require("vim.ui.clipboard.osc52").paste "+",
    ["*"] = require("vim.ui.clipboard.osc52").paste "*",
  },
}

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

vim.opt.winminwidth = 5

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

vim.opt.display = "lastline" -- long lines fit on one line

vim.o.modeline = false

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

opt.showbreak = "↳"

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

--  INFO: 2024-06-28 - Indenting - tabs
vim.bo.expandtab = true
vim.bo.shiftwidth = 2
vim.opt.smarttab = true -- Makes tabbing smarter will realize you have 2 vs 4
vim.opt.tabstop = 1
vim.opt.softtabstop = 2
vim.opt.wm = 0 -- Set textwidth, but don't automatically insert newline at given column

--  INFO: 2024-06-25 - Show tabline? navic
vim.opt.showtabline = 1

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true

vim.opt.cursorline = true
o.cursorlineopt = "both" -- to enable cursorline!
opt.iskeyword:append "-"

vim.o.errorbells = false
vim.o.visualbell = false

-- No double spaces with join after a dot
vim.opt.joinspaces = false

vim.opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}

vim.opt.listchars = {
  tab = "→ ",
  trail = "•",
  precedes = "«",
  extends = "»",
  eol = "↲",
  nbsp = "░",
}

-- vim.opt.shortmess:append "sI"
vim.opt.shortmess = {
  o = true,
  A = true, -- ignore annoying swap file messages
  c = true, -- Do not show completion messages in command line
  F = true, -- Do not show file info when editing a file, in the command line
  I = true, -- Do not show the intro message
  W = true, -- Do not show "written" in command line when writing
  sI = true,
}

vim.o.wildmenu = true
vim.o.wildoptions = "pum"

-- Ignore case when completing file names and directories.
vim.o.wildignorecase = true

vim.opt.backupcopy = "yes"
-- vim.opt.undolevels = 1000
vim.opt.autoread = true

vim.opt.conceallevel = 2
-- Use ripgrep as grep tool
vim.o.grepprg = "rg --vimgrep --no-heading --smart-case"
vim.o.grepformat = "%f:%l:%c:%m,%f:%l:%m"

-- completion
vim.opt.pumheight = 10 -- Makes popup menu smaller

-- Numbers
vim.opt.signcolumn = "yes:1"
vim.opt.inccommand = "split"
vim.o.history = 10000 -- Number of command-lines that are remembered

-- Window
vim.opt.splitkeep = "cursor" -- topline/screen/cursor
vim.o.equalalways = false
-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Buffer
vim.opt.swapfile = false
vim.opt.fileformat = "unix"
vim.opt.autochdir = true
vim.opt.shiftround = true
vim.opt.virtualedit = "block"
vim.opt.switchbuf = "useopen,uselast"

-- opt.colorcolumn = "80"
opt.autowriteall = true
opt.mousemoveevent = true
opt.relativenumber = true
opt.number = true

vim.o.lazyredraw = false -- Faster scrolling
vim.o.redrawtime = 100

vim.cmd [[set nowrap]] -- Display long lines as just one line

vim.opt.showmode = false

-- Save undo history
vim.opt.undofile = true

vim.opt.wrapscan = true

vim.opt.smoothscroll = true
vim.opt.statuscolumn = [[%!v:lua.require'ui.statuscolumn'.statuscolumn()]]

-- Recognize numbered lists when formatting text
opt.formatoptions:append "n"

-- Folding
vim.opt.foldlevel = 99

-- HACK: causes freezes on <= 0.9, so only enable on >= 0.10 for now
if vim.fn.has "nvim-0.10" == 1 then
  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = [[v:lua.require'ui.folds'.foldexpr()]]
else
  vim.opt.foldmethod = "indent"
end

vim.opt.scrolloff = 8
vim.opt.sidescroll = 6

-- make backspace behave in a sane manner
vim.opt.backspace = "indent,eol,start"

-- searching
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.smartcase = true
vim.opt.ignorecase = true

-- enable auto indentation
vim.opt.smartindent = true
vim.opt.autoindent = true

vim.opt.sessionoptions = {
  "resize",
  "winpos",
  "winsize",
  "terminal",
  "localoptions",
  "buffers",
  "curdir",
  "tabpages",
  "winsize",
  "help",
  "globals",
  "skiprtp",
  "folds",
}

opt.gcr = {
  "i-c-ci-ve:blinkoff500-blinkon500-block-TermCursor",
  "i-ci:ver30-Cursor-blinkwait500-blinkon400-blinkoff300",
  "n-v:block-Curosr/lCursor-blinkon10",
  "o:hor50-Curosr/lCursor",
  "r-cr:hor20-Curosr/lCursor",
}

-- Use histogram algorithm for diffing, generates more readable diffs in
-- situations where two lines are swapped
opt.diffopt:append {
  "algorithm:histogram",
  "indent-heuristic",
}

-- Align columns in quickfix window
opt.quickfixtextfunc = [[v:lua.require'utils.misc'.qftf]]

opt.backup = true
opt.backupdir:remove "."
vim.opt.writebackup = true
vim.opt.showcmd = false
vim.opt.showmatch = false
vim.opt.startofline = true
vim.opt.hidden = true

-- opt.cmdheight = 1
vim.o.laststatus = 3

vim.cmd [[
  let &t_Cs = "\e[4:3m"
  let &t_Ce = "\e[4:0m"
]]

-- add binaries installed by mason.nvim to path
local is_windows = vim.fn.has "win32" ~= 0
vim.env.PATH = vim.fn.stdpath "data" .. "/mason/bin" .. (is_windows and ";" or ":") .. vim.env.PATH

--  NOTE: 2024-05-14 - Disabled this, using nvterm
-- term
-- vim.api.nvim_create_autocmd("TermOpen", {
--   desc = "Set up terminal config",
--   group = vim.api.nvim_create_augroup("TermSetup", {}),
--   callback = function(info)
--     require("term").setup(info.buf)
--   end,
-- })

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  callback = function()
    require "ui.highlights"
  end,
})

-- if last command was line-jump, remove it from history to reduce noise
vim.api.nvim_create_autocmd("CmdlineLeave", {
  callback = function(ctx)
    if not ctx.match == ":" then
      return
    end
    vim.defer_fn(function()
      local lineJump = vim.fn.histget(":", -1):match "^%d+$"
      if lineJump then
        vim.fn.histdel(":", -1)
      end
    end, 100)
  end,
})

-- automatically cleanup dirs to prevent bloating.
-- once a week, on first FocusLost, delete files older than 30/60 days.
vim.api.nvim_create_autocmd("FocusLost", {
  once = true,
  callback = function()
    if os.date "%a" == "Mon" then
      vim.fn.system { "find", opt.viewdir:get(), "-mtime", "+60d", "-delete" }
      vim.fn.system { "find", opt.undodir:get()[1], "-mtime", "+30d", "-delete" }
    end
  end,
})

-- make `:substitute` also notify how many changes were made
-- works, as `CmdlineLeave` is triggered before the execution of the command
vim.api.nvim_create_autocmd("CmdlineLeave", {
  callback = function(ctx)
    if not ctx.match == ":" then
      return
    end
    local cmdline = vim.fn.getcmdline()
    local isSubstitution = cmdline:find "s ?/.+/.-/%a*$"
    if isSubstitution then
      vim.cmd(cmdline .. "ne")
    end
  end,
})

local small_dot = " "
local icons = require("utils").static.icons
vim.diagnostic.config {
  severity_sort = true,
  -- float = {
  --   show_header = false,
  --   close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
  --   scope = "cursor",
  --   source = "if_many",
  --   border = "single",
  --   focusable = false,
  -- },
  inlay_hints = {
    enabled = true,
  },
  virtual_text = {
    prefix = vim.trim(icons.TriangleUp), -- Could be '●', '▎', │, 'x', '■', , 
  },
  jump = {
    float = true,
  },
  float = { border = "single" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = vim.trim(icons.Diamond),
      [vim.diagnostic.severity.WARN] = vim.trim(icons.TriangleUp),
      [vim.diagnostic.severity.INFO] = small_dot,
      [vim.diagnostic.severity.HINT] = small_dot,
    },
    linehl = {
      [vim.diagnostic.severity.ERROR] = "ErrorMsg",
    },
    numhl = {
      [vim.diagnostic.severity.WARN] = "WarningMsg",
    },
  },
}

-- Fzf settings
g.fzf_layout = {
  window = {
    width = 0.7,
    height = 0.7,
    pos = "center",
  },
}

env.FZF_DEFAULT_OPTS = (env.FZF_DEFAULT_OPTS or "") .. " --border=sharp --margin=0 --padding=0"
-- Disable some builtin providers
vim.g.loaded_python_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0
