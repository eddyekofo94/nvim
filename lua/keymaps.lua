---------------------------------------------------------------------------------------------------+
-- Commands \ Modes | Normal | Insert | Command | Visual | Select | Operator | Terminal | Lang-Arg |
-- ================================================================================================+
-- map  / noremap   |    @   |   -    |    -    |   @    |   @    |    @     |    -     |    -     |
-- nmap / nnoremap  |    @   |   -    |    -    |   -    |   -    |    -     |    -     |    -     |
-- map! / noremap!  |    -   |   @    |    @    |   -    |   -    |    -     |    -     |    -     |
-- imap / inoremap  |    -   |   @    |    -    |   -    |   -    |    -     |    -     |    -     |
-- cmap / cnoremap  |    -   |   -    |    @    |   -    |   -    |    -     |    -     |    -     |
-- vmap / vnoremap  |    -   |   -    |    -    |   @    |   @    |    -     |    -     |    -     |
-- xmap / xnoremap  |    -   |   -    |    -    |   @    |   -    |    -     |    -     |    -     |
-- smap / snoremap  |    -   |   -    |    -    |   -    |   @    |    -     |    -     |    -     |
-- omap / onoremap  |    -   |   -    |    -    |   -    |   -    |    @     |    -     |    -     |
-- tmap / tnoremap  |    -   |   -    |    -    |   -    |   -    |    -     |    @     |    -     |
-- lmap / lnoremap  |    -   |   @    |    @    |   -    |   -    |    -     |    -     |    @     |
---------------------------------------------------------------------------------------------------+

local utils = require "utils.keymaps"
local utils_gen = require "utils.general"
local utils_buffer = require "utils.buffer"
local map = utils.set_keymap
local lmap = utils.set_leader_keymap
local nxo = utils.nxo
local maps = require("utils.keymaps").empty_map_table()
local Buffers = require "utils.buffer"

local Keymap = {}

Keymap.__index = Keymap
function Keymap.new(mode, lhs, rhs, opts)
  local action = function()
    if type(opts) == "string" then
      opts = { desc = opts }
    end
    local merged_opts = vim.tbl_extend("force", { noremap = true, silent = true }, opts or {})
    vim.keymap.set(mode, lhs, rhs, merged_opts)
  end
  return setmetatable({ action = action }, Keymap)
end

function Keymap:bind(nextMapping)
  self.action()
  return nextMapping
end

function Keymap:execute()
  self.action()
end

map({ "n", "v" }, "<leader>ll", function()
  local state = vim.o.number
  vim.o.number = not state
  vim.o.relativenumber = not state
end, { desc = "toggle [l]ine number mode" })

-- Diagnostic keymaps
map("n", "<leader>de", vim.diagnostic.open_float, { desc = "Show [d]iagnostic [E]rror messages" })
map("n", "<leader>qf", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uick[f]ix list" })

map({ "x", "n" }, "<C-w>", "<C-w>w")
map({ "x", "n" }, "<C-h>", "<C-w>h")
map({ "x", "n" }, "<C-j>", "<C-w>j")
map({ "x", "n" }, "<C-k>", "<C-w>k")
map({ "x", "n" }, "<C-l>", "<C-w>l")

--  INFO: Buffers
Keymap
  .new("n", "<leader>wh", function()
    return Buffers.hide_window(0)
  end, "Hide window")
  :bind(Keymap.new("n", "<leader>wx", function()
    return Buffers.close_window()
  end, "Close all windows but current"))
  :bind(Keymap.new("n", "<leader>wX", function()
    return Buffers.close_all_visible_window(false)
  end, "Close all windows but current"))
  :bind(Keymap.new("n", "<leader>bH", function()
    Buffers.close_all_empty_buffers()
  end, "Close hidden/empty buffers"))
  :bind(Keymap.new("n", "<leader>bx", function()
    Buffers.close_buffer(0, false)
  end, "Close all buffers except current"))
  :bind(Keymap.new("n", "<leader>bX", function()
    Buffers.close_all_buffers(true, true)
  end, "Close all buffers except current"))
  :bind(Keymap.new("n", "<leader>bR", function()
    Buffers.reset()
  end, "Close all buf/win except current"))
  -- :bind(Keymap.new())
  --  TODO: 2024-02-15 13:25 PM - Implement this in the near
  -- future
  -- ["<leader>wV"] = {
  --   function()
  --     return Buffers.close_all_hidden_buffers()
  --   end,
  --   "Close all windows but current",
  -- },
  :execute()

Keymap.new("i", "<C-b>", "<ESC>^i")
  :bind(Keymap.new("i", "<C-c>", "<esc>", "CTRL-C doesn't trigger the InsertLeave autocmd . map to <ESC> instead."))
  :bind(Keymap.new("i", "<C-a>", "<End>"))
  :bind(Keymap.new("i", "<C-l>", function()
    return utils.escapePair()
  end, "move over a closing element in insert mode"))
  :execute()

-- INFO: Search always center
Keymap.new("n", "<C-u>", "zz<C-u>")
  :bind(Keymap.new("n", "<C-d>", "zz<C-d>"))
  :bind(Keymap.new("n", "{", "zz{"))
  :bind(Keymap.new("n", "}", "zz}"))
  :bind(Keymap.new("n", "n", function()
    vim.cmd.normal {
      "zzn",
      bang = true,
      mods = { emsg_silent = true },
    }
  end))
  :bind(Keymap.new("n", "N", function()
    vim.cmd.normal {
      "zzN",
      bang = true,
      mods = { emsg_silent = true },
    }
  end))
  :bind(Keymap.new("n", "<C-i>", "zz<C-i>"))
  :bind(Keymap.new("n", "<C-o>", "zz<C-o>"))
  :bind(Keymap.new("n", "%", "zz%"))
  :bind(Keymap.new("n", "*", "zz*"))
  :bind(Keymap.new("n", "#", "zz#"))
  :execute()

--  INFO: General
--  TODO: 2024-07-04 - Turn this to a Lua method, 0 = first character on the line
-- function! LineHome()
--   let x = col('.')
--   execute "normal ^"
--   if x == col('.')
--     unmap 0
--     execute "normal 0"
--     map 0 :call LineHome()<CR>:echo<CR>
--   endif
--   return ""
-- endfunction
Keymap.new("n", "<leader>hh", "<cmd>nohl<BAR>redraws<cr>", "Clear highlight")
  :bind(
    -- Clear search, diff update and redraw
    -- taken from runtime/lua/_editor.lua
    Keymap.new("n", "<leader>ur", "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>", { desc = "Redraw / clear hlsearch / diff update" })
  )
  :bind(Keymap.new({ "i", "n" }, "<esc>", "<cmd>noh<bar>redraws<cr><esc>", "Escape and clear hlsearch"))
  :bind(Keymap.new("n", "<leader>mm", "<cmd>messages<cr>"))
  :bind(Keymap.new("n", "<leader>oo", ':<C-u>call append(line("."),   repeat([""], v:count1))<CR>', "insert line below"))
  :bind(Keymap.new("n", "<leader>OO", ':<C-u>call append(line(".")-1, repeat([""], v:count1))<CR>', "insert line above"))
  :bind(Keymap.new("n", "<leader>L", "<cmd>Lazy<CR>", "Lazy"))
  :bind(Keymap.new("n", "<leader>N", "<cmd>Noice<CR>", "Noice"))
  :bind(Keymap.new("n", "<leader>M", "<cmd>Mason<CR>", "Mason"))
  :bind(Keymap.new("n", "<leader>zz", "<cmd>ZenMode<cr>", "Zen mode"))
  :bind(Keymap.new("n", "<leader>ca", ": %y+<CR>", "COPY EVERYTHING/ALL"))
  :bind(Keymap.new("v", "/", '"fy/\\V<C-R>f<CR>'))
  :bind(Keymap.new("v", "*", '"fy/\\V<C-R>f<CR>'))
  :bind(Keymap.new(nxo, "gh", "g^", " move to start of line"))
  :bind(Keymap.new(nxo, "gl", "g$", " move to end of line"))
  :bind(Keymap.new("x", "p", '"_dP', "don't yank on paste"))
  :bind(Keymap.new("x", "v", "$h", "select until end"))
  :bind(Keymap.new("x", "p", '"_dP', "don't yank on paste"))
  :bind(Keymap.new({ "n", "x" }, "c", '"_c'))
  :bind(Keymap.new({ "n", "x" }, "C", '"_C'))
  :bind(Keymap.new({ "n", "x" }, "S", '"_S', "Don't save to register"))
  :bind(Keymap.new({ "n", "x" }, "x", '"_x'))
  :bind(Keymap.new("x", "X", '"_c'))
  :bind(Keymap.new("n", "<M-l>", function()
    return utils.escapePair()
  end, "move over a closing element in normal mode"))
  :bind(Keymap.new("n", "[q", vim.cmd.cprev, { desc = "Previous quickfix" }))
  :bind(Keymap.new("n", "]q", vim.cmd.cnext, { desc = "Next quickfix" }))
  :execute()

-- INFO: using:   "max397574/better-escape.nvim",
-- keymap("i", "jj", "<ESC>", "Escape")

-- better up/down
-- INFO: don't know about this
-- keymap({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
-- keymap({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

--  INFO: 2024-03-21 15:42 PM - Disabled for now
-- keymap({ "n", "x" }, "*", "*N", "Search word or selection")

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next search result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev search result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })
map(nxo, "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map(nxo, "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })

-- Terminal mode keymaps
-- stylua: ignore start
map('t', '<C-6>', [[v:lua.require'utils.term'.running_tui() ? "<C-6>" : "<Cmd>b#<CR>"]],        { expr = true, replace_keycodes = false })
map('t', '<C-^>', [[v:lua.require'utils.term'.running_tui() ? "<C-^>" : "<Cmd>b#<CR>"]],        { expr = true, replace_keycodes = false })
map('t', '<Esc>', [[v:lua.require'utils.term'.running_tui() ? "<Esc>" : "<Cmd>stopi<CR>"]],     { expr = true, replace_keycodes = false })
map('t', '<M-v>', [[v:lua.require'utils.term'.running_tui() ? "<M-v>" : "<Cmd>wincmd v<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-s>', [[v:lua.require'utils.term'.running_tui() ? "<M-s>" : "<Cmd>wincmd s<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-W>', [[v:lua.require'utils.term'.running_tui() ? "<M-W>" : "<Cmd>wincmd W<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-H>', [[v:lua.require'utils.term'.running_tui() ? "<M-H>" : "<Cmd>wincmd H<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-J>', [[v:lua.require'utils.term'.running_tui() ? "<M-J>" : "<Cmd>wincmd J<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-K>', [[v:lua.require'utils.term'.running_tui() ? "<M-K>" : "<Cmd>wincmd K<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-L>', [[v:lua.require'utils.term'.running_tui() ? "<M-L>" : "<Cmd>wincmd L<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-r>', [[v:lua.require'utils.term'.running_tui() ? "<M-r>" : "<Cmd>wincmd r<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-R>', [[v:lua.require'utils.term'.running_tui() ? "<M-R>" : "<Cmd>wincmd R<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-x>', [[v:lua.require'utils.term'.running_tui() ? "<M-x>" : "<Cmd>wincmd x<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-p>', [[v:lua.require'utils.term'.running_tui() ? "<M-p>" : "<Cmd>wincmd p<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-c>', [[v:lua.require'utils.term'.running_tui() ? "<M-c>" : "<Cmd>wincmd c<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-q>', [[v:lua.require'utils.term'.running_tui() ? "<M-q>" : "<Cmd>wincmd q<CR>"]],  { desc = "close",expr = true, replace_keycodes = false })
map('t', '<M-o>', [[v:lua.require'utils.term'.running_tui() ? "<M-o>" : "<Cmd>wincmd o<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-w>', [[v:lua.require'utils.term'.running_tui() ? "<M-w>" : "<Cmd>wincmd w<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-h>', [[v:lua.require'utils.term'.running_tui() ? "<M-h>" : "<Cmd>wincmd h<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-j>', [[v:lua.require'utils.term'.running_tui() ? "<M-j>" : "<Cmd>wincmd j<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-k>', [[v:lua.require'utils.term'.running_tui() ? "<M-k>" : "<Cmd>wincmd k<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-l>', [[v:lua.require'utils.term'.running_tui() ? "<M-l>" : "<Cmd>wincmd l<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-=>', [[v:lua.require'utils.term'.running_tui() ? "<M-=>" : "<Cmd>wincmd =<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-_>', [[v:lua.require'utils.term'.running_tui() ? "<M-_>" : "<Cmd>wincmd _<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-|>', [[v:lua.require'utils.term'.running_tui() ? "<M-|>" : "<Cmd>wincmd |<CR>"]],  { expr = true, replace_keycodes = false })
map('t', '<M-+>', [[v:lua.require'utils.term'.running_tui() ? "<M-+>" : "<Cmd>wincmd 2+<CR>"]], { expr = true, replace_keycodes = false })
map('t', '<M-->', [[v:lua.require'utils.term'.running_tui() ? "<M-->" : "<Cmd>wincmd 2-<CR>"]], { expr = true, replace_keycodes = false })
map('t', '<M->>', [[v:lua.require'utils.term'.running_tui() ? "<M->>" : "<Cmd>wincmd 4" . (winnr() == winnr("l") ? "<" : ">") . "<CR>"]], { expr = true })
map('t', '<M-<>', [[v:lua.require'utils.term'.running_tui() ? "<M-<>" : "<Cmd>wincmd 4" . (winnr() == winnr("l") ? ">" : "<") . "<CR>"]], { expr = true })
map('t', '<M-;>', [[v:lua.require'utils.term'.running_tui() ? "<M-.>" : "<Cmd>wincmd 4" . (winnr() == winnr("l") ? "<" : ">") . "<CR>"]], { expr = true })
map('t', '<M-,>', [[v:lua.require'utils.term'.running_tui() ? "<M-,>" : "<Cmd>wincmd 4" . (winnr() == winnr("l") ? ">" : "<") . "<CR>"]], { expr = true })
-- stylua: ignore end

-- Use <C-\><C-r> to insert contents of a register in terminal mode
map("t", [[<C-\><C-r>]], [['<C-\><C-n>"' . nr2char(getchar()) . 'pi']], { expr = true })

-- highlights under cursor
map("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })

map("t", "<C-x>", vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, true, true), "Escape terminal mode")

-- quit
map("n", "<leader>qq", "<cmd>qa<cr>", "Quit all")

--  NOTE: 2024-05-29 - Plugins

map("n", "<leader>-", function()
  require("triptych").toggle_triptych()
end, "[Triptych] files")

map("n", "<leader>.", function()
  return MiniFiles.open(vim.api.nvim_buf_get_name(0))
end, "[Mini] files")

lmap("U", "<cmd>UndotreeShow<cr>", "Undotree")

map("n", "i", function()
  if #vim.fn.getline "." == 0 then
    return [["_cc]]
  else
    return "i"
  end
end, { expr = true, desc = "rebind 'i' to do a smart-indent if its a blank line" })

map("n", "dd", function()
  if vim.api.nvim_get_current_line():match "^%s*$" then
    return '"_dd'
  else
    return "dd"
  end
end, { expr = true, desc = "Don't yank empty lines into the main register" })

-- Abbreviations
map("!a", "ture", "true")
map("!a", "Ture", "True")
map("!a", "flase", "false")
map("!a", "false", "false")
map("!a", "Flase", "False")
map("!a", "False", "False")
map("!a", "lcaol", "local")
map("!a", "lcoal", "local")
map("!a", "local", "local")
map("!a", "sahre", "share")
map("!a", "saher", "share")
map("!a", "balme", "blame")

vim.api.nvim_create_autocmd("CmdlineEnter", {
  once = true,
  callback = function()
    if utils_gen.is_available "telescope.nvim" then
      utils.command_abbrev("tel", "Telescope")
    end

    -- utils.command_map("S%", "%s/")
    utils.command_abbrev(":", "lua")
    utils.command_abbrev("Qa", "qa")
    utils.command_abbrev("QA", "qa")
    utils.command_abbrev("man", "Man")
    utils.command_abbrev("W", "w")
    utils.command_abbrev("Wqa", "wqa")
    utils.command_abbrev("Wq", "wq")
    utils.command_abbrev("Wa", "wa")
    utils.command_abbrev("ep", "e%:p:h")
    utils.command_abbrev("vep", "vs%:p:h")
    utils.command_abbrev("sep", "sp%:p:h")
    utils.command_abbrev("tep", "tabe%:p:h")
    utils.command_abbrev("rm", "!rm")
    utils.command_abbrev("mv", "!mv")
    utils.command_abbrev("Xa", "xa")
    utils.command_abbrev("mkd", "!mkdir")
    utils.command_abbrev("mkdir", "!mkdir")
    utils.command_abbrev("touch", "!touch")
    return true
  end,
})

---@param linenr integer? line number
---@return boolean
local function is_wrapped(linenr)
  if not vim.wo.wrap then
    return false
  end
  linenr = linenr or vim.fn.line "."
  local wininfo = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  return vim.fn.strdisplaywidth(vim.fn.getline(linenr) --[[@as string]]) >= wininfo.width - wininfo.textoff
end

---@param key string
---@param remap string
---@return fun(): string
local function map_wrapped(key, remap)
  return function()
    return is_wrapped() and remap or key
  end
end

---@param key string
---@param remap string
---@return fun(): string
local function map_wrapped_cur_or_next_line_nocount(key, remap)
  return function()
    return vim.v.count == 0 and (is_wrapped() or is_wrapped(vim.fn.line "." + 1)) and remap or key
  end
end

---@param key string
---@param remap string
---@return fun(): string
local function map_wrapped_cur_or_prev_line_nocount(key, remap)
  return function()
    return vim.v.count == 0 and (is_wrapped() or is_wrapped(vim.fn.line "." - 1)) and remap or key
  end
end

---@param key string
---@param remap string
---@return fun(): string
local function map_wrapped_first_line_nocount(key, remap)
  return function()
    return vim.v.count == 0 and is_wrapped(1) and remap or key
  end
end

---@param key string
---@param remap string
---@return fun(): string
local function map_wrapped_last_line_nocount(key, remap)
  return function()
    return vim.v.count == 0 and is_wrapped(vim.fn.line "$") and remap or key
  end
end

---@param key string
---@param remap string
---@return fun(): string
local function map_wrapped_eol(key, remap)
  local remap_esc = vim.api.nvim_replace_termcodes(remap, true, true, true)
  return function()
    if not is_wrapped() then
      return key
    end
    vim.api.nvim_feedkeys(remap_esc, "nx", false)
    return vim.fn.col "." == vim.fn.col "$" - 1 and key or remap
  end
end

map({ "n", "x" }, "j", map_wrapped_cur_or_next_line_nocount("j", "gj"), { expr = true })
map({ "n", "x" }, "k", map_wrapped_cur_or_prev_line_nocount("k", "gk"), { expr = true })
map({ "n", "x" }, "<Down>", map_wrapped_cur_or_next_line_nocount("<Down>", "g<Down>"), { expr = true })
map({ "n", "x" }, "<Up>", map_wrapped_cur_or_prev_line_nocount("<Up>", "g<Up>"), { expr = true })
map({ "n", "x" }, "gg", map_wrapped_first_line_nocount("gg", "gg99999gk"), { expr = true })
map({ "n", "x" }, "G", map_wrapped_last_line_nocount("G", "G99999gj"), { expr = true })
map({ "n", "x" }, "<C-Home>", map_wrapped_first_line_nocount("<C-Home>", "<C-Home>99999gk"), { expr = true })
map({ "n", "x" }, "<C-End>", map_wrapped_last_line_nocount("<C-End>", "<C-End>99999gj"), { expr = true })
map({ "n", "x" }, "0", map_wrapped("0", "g0"), { expr = true })
map({ "n", "x" }, "$", map_wrapped_eol("$", "g$"), { expr = true })
map({ "n", "x" }, "^", map_wrapped("^", "g^"), { expr = true })
map({ "n", "x" }, "<Home>", map_wrapped("<Home>", "g<Home>"), { expr = true })
map({ "n", "x" }, "<End>", map_wrapped_eol("<End>", "g<End>"), { expr = true })

map("n", "vA", "ggVG", "Select All")
map("n", "yA", "ggVGy", "Copy All")

map("n", "[e", function()
  vim.diagnostic.goto_prev { severity = "ERROR" }
end, "Error")
map("n", "]e", function()
  vim.diagnostic.goto_next { severity = "ERROR" }
end, "Error")

maps.n["<leader>bsp"] = {
  function()
    utils_buffer.sort "full_path"
  end,
  desc = "By full path",
}

maps.n["<leader>bsi"] = {
  function()
    utils_buffer.sort "bufnr"
  end,
  desc = "By buffer number",
}

maps.n["<leader>bsm"] = {
  function()
    utils_buffer.sort "modified"
  end,
  desc = "By modification",
}

maps.n["<S-x>"] = {
  function()
    utils_buffer.close_buffer(0, true)
  end,
  desc = "Force close buffer",
}

utils.set_mappings(maps)
