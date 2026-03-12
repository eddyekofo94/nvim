local M = {}
local term_utils = require "utils.term"

-- Terminal state
local _last_term_buf = nil
local _term_fullscreen = false
local _term_normal_height = 16

-- Create TermOpen autocmd at module load time (not lazily)
local groupid = vim.api.nvim_create_augroup("term", {})

local function term_init(buf)
  buf = vim._resolve_bufnr(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].bt ~= "terminal" then
    return
  end

  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.wo[win][0].nu = false
    vim.wo[win][0].rnu = false
    vim.wo[win][0].spell = false
    vim.wo[win][0].statuscolumn = ""
    vim.wo[win][0].signcolumn = "no"
  end

  -- Start with insert mode in new terminals
  vim.schedule(function()
    if vim.api.nvim_get_current_buf() == buf then
      vim.cmd.startinsert()
    end
  end)

  -- Create commands to rename terminals
  vim.api.nvim_buf_create_user_command(buf, "TermRename", function(args)
    M.rename(args.args)
  end, {
    nargs = "?",
    desc = "Rename current terminal",
    complete = function()
      local term_names = {}

      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[b].bt ~= "terminal" then
          goto continue
        end
        local _, _, _, name =
          term_utils.parse_name(vim.api.nvim_buf_get_name(b))
        if name == "" then
          goto continue
        end
        term_names[name] = true
        ::continue::
      end

      local compl = {}
      local _, _, _, curr_name =
        term_utils.parse_name(vim.api.nvim_buf_get_name(0))
      for name, _ in pairs(term_names) do
        if name == curr_name then
          table.insert(compl, 1, name)
        else
          table.insert(compl, name)
        end
      end

      return compl
    end,
  })

  vim.api.nvim_buf_create_user_command(buf, "TermSetCmd", function(args)
    M.set_cmd(args.args)
  end, {
    nargs = "?",
    desc = "Set cmd for current terminal",
    complete = "shellcmdline",
  })

  vim.api.nvim_buf_create_user_command(buf, "TermSetPath", function(args)
    M.set_path(args.args)
  end, {
    nargs = "?",
    desc = "Set path for current terminal",
    complete = "dir",
  })

  vim.api.nvim_buf_create_user_command(buf, "TermRerun", function(args)
    M.rerun(tonumber(args.args))
  end, {
    nargs = "?",
    desc = "Re-run terminal command",
    complete = function()
      local terms = {}

      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[b].bt == "terminal" then
          table.insert(
            terms,
            string.format("%d (%s)", b, vim.api.nvim_buf_get_name(b))
          )
        end
      end

      return terms
    end,
  })
end

vim.api.nvim_create_autocmd("TermOpen", {
  group = groupid,
  desc = "Set terminal keymaps and options, open term in split.",
  callback = function(args)
    term_init(args.buf)
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  group = groupid,
  pattern = "term://*",
  callback = function(args)
    -- Set Alt+. to send last command argument in terminal
    vim.keymap.set(
      "t",
      "<M-.>",
      "<C-v><M-.>",
      { buffer = args.buf, silent = true }
    )
  end,
})

-- Initialize existing terminal buffers
vim
  .iter(vim.api.nvim_list_bufs())
  :filter(function(buf)
    return vim.bo[buf].bt == "terminal"
  end)
  :each(function(buf)
    term_init(buf)
  end)

---@param buf? integer terminal buffer id
---@return boolean
local function validate_term_buf(buf)
  buf = vim._resolve_bufnr(buf)
  if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].bt == "terminal" then
    return true
  end
  vim.notify(
    string.format("[plugin.term] buffer %d is not a terminal buffer", buf),
    vim.log.levels.WARN
  )
  return false
end

---@param cmd? string new command
---@param buf? integer terminal buffer id
function M.set_cmd(cmd, buf)
  buf = vim._resolve_bufnr(buf)
  if not validate_term_buf(buf) then
    return
  end
  ---@cast cmd string
  if not cmd or cmd == "" then
    return
  end
  if vim.fn.executable(cmd) == 0 then
    vim.notify(
      string.format("[plugin.term] command `%s` is not executable", cmd),
      vim.log.levels.WARN
    )
    return
  end
  vim.cmd.file(
    vim.fn.fnameescape(
      term_utils.compose_name(vim.api.nvim_buf_get_name(buf), { cmd = cmd })
    )
  )
end

---@param path? string
---@param buf? integer terminal buffer id
function M.set_path(path, buf)
  buf = vim._resolve_bufnr(buf)
  if not validate_term_buf(buf) then
    return
  end
  ---@cast path string
  if not path or path == "" then
    path = vim.fn.getcwd(0)
  end
  if not vim.fn.isdirectory(path) then
    vim.notify(
      string.format("[plugin.term] path '%s' is not a directory", path)
    )
    return
  end
  vim.cmd.file(
    vim.fn.fnameescape(
      term_utils.compose_name(vim.api.nvim_buf_get_name(buf), { path = path })
    )
  )
end

---@param buf integer? terminal buffer handler
function M.rerun(buf)
  buf = vim._resolve_bufnr(buf)
  if not validate_term_buf(buf) then
    return
  end
  vim.cmd.edit(
    vim.fn.fnameescape(
      term_utils.compose_name(vim.api.nvim_buf_get_name(buf), { pid = "" })
    )
  )
end

---@param name? string
---@param buf? integer
function M.rename(name, buf)
  buf = vim._resolve_bufnr(buf)
  if not validate_term_buf(buf) then
    return
  end
  if not name then
    return
  end
  vim.cmd.file(
    vim.fn.fnameescape(
      term_utils.compose_name(vim.api.nvim_buf_get_name(0), { name = name })
    )
  )
end

-- Make term_init available as M.term_init for backwards compatibility
M.term_init = term_init

---@param buf? integer terminal buffer id
---@return boolean

---Plugin initialize function
---@return nil
function M.setup()
  if vim.g.loaded_term_plugin ~= nil then
    return
  end
  vim.g.loaded_term_plugin = true

  -- Send Escape directly to terminal
  vim.keymap.set("t", "<Esc>", "<Esc>", { replace_keycodes = false, desc = "Send Escape to terminal" })
  -- Use `<C-\\><Esc>` instead to exit terminal mode
  vim.keymap.set(
    "t",
    "<C-\\><Esc>",
    "<Cmd>stopi<CR>",
    { replace_keycodes = false, desc = "Exit terminal mode" }
  )
  -- Make `<C-[>` the same as `<Esc>` in terminals with kitty keyboard protocol
  -- support where `<C-[>` and `<Esc>` are treated differently
  vim.keymap.set("t", "<C-[>", "<Esc>", { remap = true })

  vim
    .iter(vim.api.nvim_list_bufs())
    :filter(function(buf)
      return vim.bo[buf].bt == "terminal"
    end)
    :each(function(buf)
      M.term_init(buf)
    end)

  local groupid = vim.api.nvim_create_augroup("term", {})
  vim.api.nvim_create_autocmd("TermOpen", {
    group = groupid,
    desc = "Set terminal keymaps and options, open term in split.",
    callback = function(args)
      term_init(args.buf)
    end,
  })
end

-- Create user commands
vim.api.nvim_create_user_command("VSTerm", function()
  vim.cmd.vsplit()
  vim.cmd.terminal()
end, { desc = "Open terminal in vertical split" })

vim.api.nvim_create_user_command("STerm", function()
  vim.cmd.split()
  vim.cmd.terminal()
end, { desc = "Open terminal in horizontal split" })

vim.api.nvim_create_user_command("BTerm", function()
  vim.cmd "split"
  vim.cmd "wincmd J"
  vim.cmd "resize 16"
  vim.cmd.terminal()
  vim.b.focus_disable = true
  vim.w.focus_disable = true
end, { desc = "Open terminal at bottom" })

-- Create global keymap for Alt+i to toggle bottom terminal
vim.keymap.set("n", "<A-i>", function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].bt == "terminal" then
      _last_term_buf = buf
      vim.api.nvim_win_close(win, false)
      return
    end
  end
  if _last_term_buf and vim.api.nvim_buf_is_valid(_last_term_buf) then
    vim.cmd "split"
    vim.cmd "wincmd J"
    vim.cmd "resize 16"
    vim.api.nvim_win_set_buf(0, _last_term_buf)
    vim.b.focus_disable = true
    vim.w.focus_disable = true
  else
    vim.cmd "split"
    vim.cmd "wincmd J"
    vim.cmd "resize 16"
    vim.cmd.terminal()
    vim.b.focus_disable = true
    vim.w.focus_disable = true
  end
end, { desc = "Toggle bottom terminal" })

vim.keymap.set("t", "<A-i>", function()
  -- Hide terminal in terminal mode
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].bt == "terminal" then
      _last_term_buf = buf
      vim.api.nvim_win_close(win, false)
      return
    end
  end
end, { desc = "Toggle bottom terminal" })

vim.keymap.set({ "n", "t" }, "<A-o>", function()
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].bt ~= "terminal" then
    return
  end
  local is_fullscreen = vim.w[win].term_fullscreen
  if is_fullscreen then
    vim.cmd("resize " .. _term_normal_height)
    vim.w[win].term_fullscreen = false
  else
    vim.cmd "resize 100%"
    vim.w[win].term_fullscreen = true
  end
end, { desc = "Toggle terminal fullscreen" })

vim.keymap.set("t", "<A-|>", function()
  vim.cmd.vsplit()
  vim.cmd.terminal()
end, { desc = "Open new terminal vertically" })

vim.api.nvim_create_user_command("FTerm", function(opts)
  local cmd = opts.args and #opts.args > 0 and opts.args or vim.o.shell
  vim.cmd.terminal(cmd)
  vim.cmd "resize 100%"
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  vim.w[win].term_fullscreen = true
  vim.keymap.set("t", "q", function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end, { buffer = buf, desc = "Close terminal" })
end, { nargs = "?", desc = "Open terminal fullscreen" })

vim.api.nvim_create_user_command("LazyGit", function()
  vim.cmd.terminal("LazyGit")
  vim.cmd "resize 100%"
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  vim.w[win].term_fullscreen = true
  vim.keymap.set("t", "q", function()
    vim.api.nvim_buf_delete(buf, { force = true })
  end, { buffer = buf, desc = "Close terminal" })
end, { desc = "Open LazyGit fullscreen" })

return M
