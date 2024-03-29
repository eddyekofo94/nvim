-- Initialise eveything from here

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)
vim.g.mapleader = " "
vim.cmd("set background=dark")
vim.cmd("set termguicolors")

require("keymaps")
require("globals")
require("settings")
require("autocommands")

require("utils.hjkl_notifier")

require("lazy").setup("plugins") -- INFO: this should be on the LAST LINE
