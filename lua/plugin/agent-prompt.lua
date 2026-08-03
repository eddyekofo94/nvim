---Agent prompt editing: prompt left, the agent's closeout right.
---
---An agent's ctrl+g hands its follow-up prompt to `$EDITOR` as a temporary
---file. The closeout that prompt answers is only in the pane's scrollback, and
---Neovim cannot read it: the alternate screen is claimed before `--cmd` runs,
---and `herdr pane read` then reports the Neovim window instead. So the capture
---happens in `tools/agent_prompt_editor.sh` before this process starts, and
---arrives here as `$AGENT_CLOSEOUT_FILE`.
---
---Every check below fails to plain Neovim. A missed detection costs a split;
---a false one would hijack an ordinary edit.
local M = {}

---The agent's cwd, inherited at launch. Captured at require time, which during
---startup is before any argument file is read and before the `auto_cwd`
---autocmd can move the window to the prompt file's directory under `$TMPDIR`.
local startup_cwd = vim.uv.cwd()

---@param path string
---@return string
local function resolve(path)
  local real = vim.uv.fs_realpath(path)
  if real then
    return real
  end
  -- A path that does not exist yet still resolves through its parent.
  local parent = vim.uv.fs_realpath(vim.fs.dirname(path))
  if parent then
    return vim.fs.joinpath(parent, vim.fs.basename(path))
  end
  return vim.fs.normalize(path)
end

---@param dir string
---@param path string
---@return boolean
local function is_under(dir, path)
  dir = dir:gsub("/+$", "")
  return dir ~= "" and path:sub(1, #dir + 1) == dir .. "/"
end

---@param path string?
---@return string[]?
local function read_lines(path)
  if not path or path == "" or vim.fn.filereadable(path) ~= 1 then
    return nil
  end
  local lines = vim.fn.readfile(path)
  if type(lines) ~= "table" or #lines == 0 then
    return nil
  end
  return lines
end

---@param buf integer
---@return boolean
local function is_empty(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return #lines == 0 or (#lines == 1 and lines[1] == "")
end

---@class AgentPrompt.Target
---@field file string Resolved path of the prompt file
---@field closeout string Path of the captured closeout
---@field seed string? Path of the captured ready-to-paste block

---Decide whether this Neovim was launched as an agent's prompt editor.
---
---`$AGENT_CLOSEOUT_FILE` is the load-bearing signal: only the shim sets it, and
---only after a closeout was actually extracted. `$AI_AGENT` and `$CLAUDECODE`
---are deliberately not used — every child of an agent shell inherits those.
---@param opts? { args?: string[], closeout?: string, seed?: string, tmpdir?: string }
---@return AgentPrompt.Target?
function M.detect(opts)
  opts = opts or {}

  local closeout = opts.closeout or vim.env.AGENT_CLOSEOUT_FILE
  if not closeout or closeout == "" or vim.fn.filereadable(closeout) ~= 1 then
    return nil
  end

  local args = opts.args or vim.fn.argv()
  if type(args) ~= "table" or #args ~= 1 or args[1] == "" then
    return nil
  end

  local tmpdir = opts.tmpdir or vim.env.TMPDIR
  if not tmpdir or tmpdir == "" then
    return nil
  end

  -- Agents write the prompt file under $TMPDIR. Resolve both sides: on macOS
  -- $TMPDIR is a symlinked /var/folders path, and an unresolved compare would
  -- reject every real prompt file.
  local file = resolve(vim.fn.fnamemodify(args[1], ":p"))
  if not is_under(resolve(tmpdir), file) then
    return nil
  end

  local seed = opts.seed or vim.env.AGENT_PROMPT_SEED_FILE
  return {
    file = file,
    closeout = closeout,
    seed = (seed ~= "" and seed) or nil,
  }
end

---@param target AgentPrompt.Target
---@return integer? win
local function open_closeout(target)
  local lines = read_lines(target.closeout)
  if not lines then
    return nil
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_name(buf, "agent://closeout")
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false

  local win = vim.api.nvim_open_win(buf, false, {
    split = "right",
    win = 0,
  })
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].wrap = true
  vim.wo[win].spell = false
  vim.wo[win].winfixwidth = true

  -- Read-only reference, but still a real window: yankable, searchable and
  -- scrollable on its own.
  vim.keymap.set("n", "q", "<C-w>c", { buffer = buf, nowait = true })

  return win
end

---Lay out the prompt editor. Operates on the current window, so a spec can
---drive it without a real agent launch.
---@param target AgentPrompt.Target
---@param cwd? string Defaults to Neovim's startup cwd
---@return integer? closeout_win
function M.open(target, cwd)
  local prompt_win = vim.api.nvim_get_current_win()
  local prompt_buf = vim.api.nvim_win_get_buf(prompt_win)

  M.mark(prompt_buf)

  -- The window, not the process: `@` completion, `:e`, `:grep` and fzf-lua all
  -- read the window's cwd, and without this they point at $TMPDIR.
  cwd = cwd or startup_cwd
  if cwd and vim.fn.isdirectory(cwd) == 1 then
    vim.api.nvim_win_call(prompt_win, function()
      pcall(vim.cmd.lcd, {
        cwd,
        mods = { silent = true, emsg_silent = true },
      })
    end)
  end

  -- Only an empty buffer is seeded, and as one change: `u` clears it for the
  -- write-from-scratch case. A prompt the agent handed over with content is
  -- the user's text and is never touched.
  if is_empty(prompt_buf) and vim.bo[prompt_buf].modifiable then
    local seed = read_lines(target.seed)
    if seed then
      vim.api.nvim_buf_set_lines(prompt_buf, 0, -1, false, seed)
    end
  end

  local closeout_win = open_closeout(target)
  if closeout_win and vim.api.nvim_win_is_valid(prompt_win) then
    vim.api.nvim_set_current_win(prompt_win)
  end

  return closeout_win
end

---Exempt a buffer from the `auto_cwd` autocmd, which would otherwise `lcd` the
---prompt window to the prompt file's directory under `$TMPDIR`.
---@param buf integer
function M.mark(buf)
  vim.b[buf].agent_prompt = true
end

---@param buf integer
---@return boolean
function M.is_prompt_buf(buf)
  return vim.b[buf].agent_prompt == true
end

function M.setup()
  local target = M.detect()
  if not target then
    return
  end

  local group = vim.api.nvim_create_augroup("agent_prompt", {})

  -- The mark has to land before the first BufEnter, or `auto_cwd` moves the
  -- window before anything can opt out.
  vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
    group = group,
    pattern = target.file,
    callback = function(args)
      M.mark(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    once = true,
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      if resolve(vim.api.nvim_buf_get_name(buf)) ~= target.file then
        return
      end
      M.open(target)
    end,
  })
end

return M
