-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- require "nvchad.mappings"

--  INFO: Utils
local utils = require 'utils.keymaps'
local utils_buffer = require 'utils.buffer'
local fs = require 'utils.fs'
local keymap = utils.set_keymap
local nxo = utils.nxo
local maps = require('utils.keymaps').empty_map_table()
local Buffers = require 'utils.buffer'

local Keymap = {}

Keymap.__index = Keymap
function Keymap.new(mode, lhs, rhs, opts)
  local action = function()
    if type(opts) == 'string' then
      opts = { desc = opts }
    end
    local merged_opts = vim.tbl_extend('force', { noremap = true, silent = true }, opts or {})
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

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })
vim.keymap.set({ 'x', 'n' }, '<C-w>', '<C-w>w')
vim.keymap.set({ 'x', 'n' }, '<C-h>', '<C-w>h')
vim.keymap.set({ 'x', 'n' }, '<C-j>', '<C-w>j')
vim.keymap.set({ 'x', 'n' }, '<C-k>', '<C-w>k')
vim.keymap.set({ 'x', 'n' }, '<C-l>', '<C-w>l')

--  INFO: Buffers
Keymap
  .new('n', '<leader>wh', function()
    return Buffers.hide_window(0)
  end, 'Hide window')
  :bind(Keymap.new('n', '<leader>wx', function()
    return Buffers.close_window()
  end, 'Close all windows but current'))
  :bind(Keymap.new('n', '<leader>wX', function()
    return Buffers.close_all_visible_window(false)
  end, 'Close all windows but current'))
  :bind(Keymap.new('n', '<leader>bH', function()
    Buffers.close_all_empty_buffers()
  end, 'Close hidden/empty buffers'))
  :bind(Keymap.new('n', '<leader>bx', function()
    Buffers.close_buffer(0, false)
  end, 'Close all buffers except current'))
  :bind(Keymap.new('n', '<leader>bX', function()
    Buffers.close_all_buffers(true, true)
  end, 'Close all buffers except current'))
  :bind(Keymap.new('n', '<leader>bR', function()
    Buffers.reset()
  end, 'Close all buf/win except current'))
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

-- INFO: Search always center
Keymap.new('n', '<C-u>', 'zz<C-u>')
  :bind(Keymap.new('n', '<C-d>', 'zz<C-d>'))
  :bind(Keymap.new('n', '{', 'zz{'))
  :bind(Keymap.new('n', '}', 'zz}'))
  :bind(Keymap.new('n', 'n', 'zzn'))
  :bind(Keymap.new('n', 'N', 'zzN'))
  :bind(Keymap.new('n', '<C-i>', 'zz<C-i>'))
  :bind(Keymap.new('n', '<C-o>', 'zz<C-o>'))
  :bind(Keymap.new('n', '%', 'zz%'))
  :bind(Keymap.new('n', '*', 'zz*'))
  :bind(Keymap.new('n', '#', 'zz#'))
  :execute()

--  INFO: General
Keymap
  .new('n', '<leader>hh', '<cmd>nohl<BAR>redraws<cr>', 'Clear highlight')
  :bind(
    -- Clear search, diff update and redraw
    -- taken from runtime/lua/_editor.lua
    Keymap.new('n', '<leader>ur', '<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>', { desc = 'Redraw / clear hlsearch / diff update' })
  )
  :bind(Keymap.new({ 'i', 'n' }, '<esc>', '<cmd>noh<bar>redraws<cr><esc>', 'Escape and clear hlsearch'))
  :bind(Keymap.new('n', '<leader>mm', '<cmd>messages<cr>'))
  :bind(Keymap.new('n', '<leader>oo', ':<C-u>call append(line("."),   repeat([""], v:count1))<CR>', 'insert line below'))
  :bind(Keymap.new('n', '<leader>OO', ':<C-u>call append(line(".")-1, repeat([""], v:count1))<CR>', 'insert line above'))
  :bind(Keymap.new('n', '<leader>L', '<cmd>Lazy<CR>', 'Lazy'))
  :bind(Keymap.new('n', '<leader>N', '<cmd>Noice<CR>', 'Noice'))
  :bind(Keymap.new('n', '<leader>M', '<cmd>Mason<CR>', 'Mason'))
  :bind(Keymap.new('n', '<leader>zz', '<cmd>ZenMode<cr>', 'Zen mode'))
  :bind(Keymap.new('n', '<leader>ca', ': %y+<CR>', 'COPY EVERYTHING/ALL'))
  :bind(Keymap.new('v', '/', '"fy/\\V<C-R>f<CR>'))
  :bind(Keymap.new('v', '*', '"fy/\\V<C-R>f<CR>'))
  :bind(Keymap.new('i', '<C-c>', '<esc>', "CTRL-C doesn't trigger the InsertLeave autocmd . map to <ESC> instead."))
  :bind(Keymap.new(nxo, 'gh', 'g^', ' move to start of line'))
  :bind(Keymap.new(nxo, 'gl', 'g$', ' move to end of line'))
  :bind(Keymap.new('x', 'p', '"_dP', "don't yank on paste"))
  :bind(Keymap.new('x', 'v', '$h', 'select until end'))
  :bind(Keymap.new('x', 'p', '"_dP', "don't yank on paste"))
  :bind(Keymap.new({ 'n', 'x' }, 'c', '"_c'))
  :bind(Keymap.new({ 'n', 'x' }, 'C', '"_C'))
  :bind(Keymap.new({ 'n', 'x' }, 'S', '"_S', "Don't save to register"))
  :bind(Keymap.new({ 'n', 'x' }, 'x', '"_x'))
  :bind(Keymap.new('x', 'X', '"_c'))
  :bind(Keymap.new('i', '<C-l>', function()
    return utils.escapePair()
  end, 'move over a closing element in insert mode'))
  :bind(Keymap.new('n', '<M-l>', function()
    return utils.escapePair()
  end, 'move over a closing element in normal mode'))
  :bind(Keymap.new('n', '[q', vim.cmd.cprev, { desc = 'Previous quickfix' }))
  :bind(Keymap.new('n', ']q', vim.cmd.cnext, { desc = 'Next quickfix' }))
  -- :bind(Keymap.new())
  -- :bind(Keymap.new())
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
-- keymap("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next search result" })
-- keymap("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev search result" })
-- keymap("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
-- keymap("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
-- keymap("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })
-- keymap("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })
-- keymap(nxo, "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
-- keymap(nxo, "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })

-- if vim.lsp.buf.inlay_hint or vim.lsp.inlay_hint then
--   keymap("n", "<leader>uh", function()
--     LazyVim.toggle.inlay_hints()
--   end, { desc = "Toggle Inlay Hints" })
-- end

-- highlights under cursor
-- Keymap("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })

-- quit
keymap('n', '<leader>qq', '<cmd>qa<cr>', 'Quit all')

keymap('n', 'i', function()
  if #vim.fn.getline '.' == 0 then
    return [["_cc]]
  else
    return 'i'
  end
end, { expr = true, desc = "rebind 'i' to do a smart-indent if its a blank line" })

keymap('n', 'dd', function()
  if vim.api.nvim_get_current_line():match '^%s*$' then
    return '"_dd'
  else
    return 'dd'
  end
end, { expr = true, desc = "Don't yank empty lines into the main register" })

-- Abbreviations
keymap('!a', 'ture', 'true')
keymap('!a', 'Ture', 'True')
keymap('!a', 'flase', 'false')
keymap('!a', 'false', 'false')
keymap('!a', 'Flase', 'False')
keymap('!a', 'False', 'False')
keymap('!a', 'lcaol', 'local')
keymap('!a', 'lcoal', 'local')
keymap('!a', 'local', 'local')
keymap('!a', 'sahre', 'share')
keymap('!a', 'saher', 'share')
keymap('!a', 'balme', 'blame')

vim.api.nvim_create_autocmd('CmdlineEnter', {
  once = true,
  callback = function()
    utils.command_abbrev('S', '%s')
    utils.command_abbrev(':', 'lua')
    utils.command_abbrev('man', 'Man')
    utils.command_abbrev('ep', 'e%:p:h')
    utils.command_abbrev('vep', 'vs%:p:h')
    utils.command_abbrev('sep', 'sp%:p:h')
    utils.command_abbrev('tep', 'tabe%:p:h')
    utils.command_abbrev('rm', '!rm')
    utils.command_abbrev('mv', '!mv')
    utils.command_abbrev('mkd', '!mkdir')
    utils.command_abbrev('mkdir', '!mkdir')
    utils.command_abbrev('touch', '!touch')
    return true
  end,
})

---@param linenr integer? line number
---@return boolean
local function is_wrapped(linenr)
  if not vim.wo.wrap then
    return false
  end
  linenr = linenr or vim.fn.line '.'
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
    return vim.v.count == 0 and (is_wrapped() or is_wrapped(vim.fn.line '.' + 1)) and remap or key
  end
end

---@param key string
---@param remap string
---@return fun(): string
local function map_wrapped_cur_or_prev_line_nocount(key, remap)
  return function()
    return vim.v.count == 0 and (is_wrapped() or is_wrapped(vim.fn.line '.' - 1)) and remap or key
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
    return vim.v.count == 0 and is_wrapped(vim.fn.line '$') and remap or key
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
    vim.api.nvim_feedkeys(remap_esc, 'nx', false)
    return vim.fn.col '.' == vim.fn.col '$' - 1 and key or remap
  end
end

keymap({ 'n', 'x' }, 'j', map_wrapped_cur_or_next_line_nocount('j', 'gj'), { expr = true })
keymap({ 'n', 'x' }, 'k', map_wrapped_cur_or_prev_line_nocount('k', 'gk'), { expr = true })
keymap({ 'n', 'x' }, '<Down>', map_wrapped_cur_or_next_line_nocount('<Down>', 'g<Down>'), { expr = true })
keymap({ 'n', 'x' }, '<Up>', map_wrapped_cur_or_prev_line_nocount('<Up>', 'g<Up>'), { expr = true })
keymap({ 'n', 'x' }, 'gg', map_wrapped_first_line_nocount('gg', 'gg99999gk'), { expr = true })
keymap({ 'n', 'x' }, 'G', map_wrapped_last_line_nocount('G', 'G99999gj'), { expr = true })
keymap({ 'n', 'x' }, '<C-Home>', map_wrapped_first_line_nocount('<C-Home>', '<C-Home>99999gk'), { expr = true })
keymap({ 'n', 'x' }, '<C-End>', map_wrapped_last_line_nocount('<C-End>', '<C-End>99999gj'), { expr = true })
keymap({ 'n', 'x' }, '0', map_wrapped('0', 'g0'), { expr = true })
keymap({ 'n', 'x' }, '$', map_wrapped_eol('$', 'g$'), { expr = true })
keymap({ 'n', 'x' }, '^', map_wrapped('^', 'g^'), { expr = true })
keymap({ 'n', 'x' }, '<Home>', map_wrapped('<Home>', 'g<Home>'), { expr = true })
keymap({ 'n', 'x' }, '<End>', map_wrapped_eol('<End>', 'g<End>'), { expr = true })

maps.n['<leader>bsp'] = {
  function()
    utils_buffer.sort 'full_path'
  end,
  desc = 'By full path',
}

maps.n['<leader>bsi'] = {
  function()
    utils_buffer.sort 'bufnr'
  end,
  desc = 'By buffer number',
}

maps.n['<leader>bsm'] = {
  function()
    utils_buffer.sort 'modified'
  end,
  desc = 'By modification',
}

maps.n['<S-x>'] = {
  function()
    utils_buffer.close_buffer(0, true)
  end,
  desc = 'Force close buffer',
}

utils.set_mappings(maps)
