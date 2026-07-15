-- Prevent loading lua files from the current directory.
-- E.g. when cwd is `lua/pack/specs/opt/`, `require('nvim-web-devicons')` will
-- load the local `nvim-web-devicons.lua` config file instead of the plugin
-- itself. This will confuse plugins that depends on `nvim-web-devicons`.
-- Subsequent calls to nvim-web-devicons' function may fail.
-- Remove the current directory from `package.path` to avoid errors.
package.path = package.path:gsub("%./%?%.lua;?", "")

-- Disable ALL prompts and press-enter messages immediately
vim.opt.more = false
vim.opt.confirm = false
vim.opt.shortmess:append("I")

-- Enable faster lua loader using byte-compilation
-- https://github.com/neovim/neovim/commit/2257ade3dc2daab5ee12d27807c0b3bcf103cd29
vim.loader.enable()

-- GUI launches do not necessarily inherit the login shell's Homebrew path.
-- Keep command-backed plugins available in that clean launch environment.
local homebrew_bin = "/opt/homebrew/bin"
local path_entries = vim.split(vim.env.PATH or "", ":", { plain = true })
if
  vim.fn.isdirectory(homebrew_bin) == 1
  and not vim.tbl_contains(path_entries, homebrew_bin)
then
  vim.env.PATH = homebrew_bin .. ":" .. (vim.env.PATH or "")
end

-- Add palettes to runtimepath for colorscheme discovery
vim.opt.runtimepath:append(vim.fn.stdpath("config") .. "/palettes")

require("core.options")
require("core.keymaps")
require("core.commands")
require("core.autocmds")
require("core.pack")
require("core.palette")

local load = require("utils.load")

load.on_events("FileType", "core.treesitter")
load.on_events("DiagnosticChanged", "core.diagnostic")
load.on_events("FileType", "core.lsp")

-- Final prompt suppression
vim.opt.more = false
vim.opt.confirm = false
