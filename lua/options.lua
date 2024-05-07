-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-------------------------------------- highlight ------------------------------------------
-- Enable faster lua loader using byte-compilation
-- https://github.com/neovim/neovim/commit/2257ade3dc2daab5ee12d27807c0b3bcf103cd29
vim.loader.enable()
-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
-- vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.opt.clipboard = "unnamedplus"

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- add yours here!
vim.g.mapleader = " "
local o = vim.o
local g = vim.g
local opt = vim.opt

-- g.has_ui = #vim.api.nvim_list_uis() > 0
vim.opt.cursorline = true
o.cursorlineopt = "both" -- to enable cursorline!
opt.iskeyword:append "-"
vim.opt.errorbells = false
vim.opt.joinspaces = false

vim.opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}

if g.modern_ui then
  opt.listchars:append { nbsp = "␣" }
  opt.fillchars:append {
    foldopen = "",
    foldclose = "",
    diff = "╱",
  }
end

vim.opt.listchars = {
  -- tab = "→\\ ",
  tab = "→ ",
  trail = "•",
  precedes = "«",
  extends = "»",
  eol = "↲",
  -- nbsp = "␣",
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

vim.opt.backupcopy = "yes"
-- vim.opt.undolevels = 1000
vim.opt.autoread = true

vim.opt.conceallevel = 0
-- Use ripgrep as grep tool
vim.o.grepprg = "rg --vimgrep --no-heading"
vim.o.grepformat = "%f:%l:%c:%m,%f:%l:%m"

-- Indenting

-- completion
vim.opt.pumheight = 10 -- Makes popup menu smaller

-- Numbers
vim.opt.signcolumn = "yes:1"
vim.opt.inccommand = "split"
vim.opt.splitkeep = "screen" -- topline
opt.splitright = true
opt.splitbelow = true
vim.o.history = 10000 -- Number of command-lines that are remembered

-- Buffer
vim.opt.swapfile = false
vim.opt.fileformat = "unix"
vim.opt.autochdir = true
vim.opt.shiftround = true

-- opt.colorcolumn = "80"
opt.autowriteall = true
opt.mousemoveevent = true
opt.relativenumber = true
o.number = true

vim.o.lazyredraw = false -- Faster scrolling
vim.o.redrawtime = 100

vim.cmd [[set nowrap]] -- Display long lines as just one line

vim.opt.showmode = false

vim.opt.undodir = vim.fn.stdpath "data" .. "undo"
vim.opt.undofile = true
vim.opt.wrapscan = true

vim.opt.smoothscroll = true
vim.opt.statuscolumn = [[%!v:lua.require'ui.statuscolumn'.statuscolumn()]]

-- Recognize numbered lists when formatting text
opt.formatoptions:append "n"

-- Folding
vim.opt.foldlevel = 99
-- vim.opt.foldtext = [[v:lua.require'ui.folds'.foldtext()]]

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
vim.opt.autoindent = true

-- vim.opt.sessionoptions = "resize,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
vim.opt.sessionoptions = {
  "resize",
  "winpos",
  -- "winsize",
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

vim.opt.list = true

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

-- Use system clipboard
opt.clipboard:append "unnamedplus"

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
o.laststatus = 3
-- Autom. save file before some action
-- vim.o.autowrite = true

vim.cmd [[
  let &t_Cs = "\e[4:3m"
  let &t_Ce = "\e[4:0m"
]]

-- add binaries installed by mason.nvim to path
local is_windows = vim.fn.has "win32" ~= 0
vim.env.PATH = vim.fn.stdpath "data" .. "/mason/bin" .. (is_windows and ";" or ":") .. vim.env.PATH

-- term
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("TermSetup", {}),
  callback = function(info)
    require("term").setup(info.buf)
  end,
})

vim.api.nvim_create_autocmd({ "VimEnter" }, {
  callback = function()
    require "ui.highlights"
  end,
})
