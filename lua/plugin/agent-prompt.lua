---Agent prompt editing: prompt left, the agent's last message right.
---
---The reference is the whole final message -- body and closeout -- because the
---questions a prompt answers live above the `Status:` line. `$AGENT_CLOSEOUT_FILE`
---keeps its name as the shim/Neovim contract; only its contents grew.
---
---An agent's ctrl+g hands its follow-up prompt to `$EDITOR` as a temporary
---file. The message that prompt answers is only in the pane's scrollback, and
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

---Environment variables an agent runtime exports into its own children. Every
---descendant of an agent shell inherits these, so they can only ever narrow a
---decision that is already pinned to a lone prompt file under a temp root.
---
---`AI_AGENT` is the cross-vendor convention — a runtime sets it to
---`<name>_<version>_agent` and leaves a foreign value alone — but only Claude
---Code actually writes it today. Every other runtime is recognised by its own
---marker, or detection would be Claude-only.
local agent_env = {
  "AI_AGENT",
  "CLAUDECODE", -- Claude Code
  "OPENCODE", -- OpenCode
  "CURSOR_AGENT", -- Cursor
  "GEMINI_CLI", -- Gemini CLI
}

---Only the Claude Code markers are confirmed against a real ctrl+g launch. The
---rest are read off each runtime's binary or launcher and stay unverified until
---an actual launch proves them; every one of them fails closed to plain Neovim.
---
---Runtimes that export a family of variables rather than one marker. Matched
---against the whole environment so a renamed session variable still registers:
---these names are vendor-exclusive, and a stray match can at worst let through
---a launch that still has to look exactly like an agent prompt file.
local agent_env_prefixes = {
  "CLAUDE_CODE_", -- Claude Code
  "CODEX_", -- Codex, which exports no single stable marker
  "OPENCODE_",
  "PI_CODING_AGENT", -- Pi, exported by `pilot.sh` before the binary starts
  "PI_PILOT_",
  "AIDER_",
}

---@param opts? { agent?: boolean, env?: table<string, string> }
---@return boolean
local function launched_by_agent(opts)
  if opts and opts.agent ~= nil then
    return opts.agent
  end

  local env = opts and opts.env
  for _, name in ipairs(agent_env) do
    local value = (env or vim.env)[name]
    if value and value ~= "" then
      return true
    end
  end

  -- Prefix matching needs the whole environment, so it only runs once every
  -- cheap exact name has missed.
  for name, value in pairs(env or vim.fn.environ()) do
    if value ~= "" then
      for _, prefix in ipairs(agent_env_prefixes) do
        if name:sub(1, #prefix) == prefix then
          return true
        end
      end
    end
  end

  return false
end

---Temp roots agents write prompt files into. `$TMPDIR` covers Codex and Pi;
---Claude Code writes under `/tmp` (`/private/tmp` once resolved), which is a
---different tree entirely on macOS.
---@param opts? { tmpdir?: string, tmpdirs?: string[] }
---@return string[]
local function tmp_roots(opts)
  opts = opts or {}
  -- A single explicit root means "only this one" — it is how a spec pins
  -- detection to a scratch directory without the real temp trees leaking in.
  local roots = opts.tmpdirs or (opts.tmpdir and { opts.tmpdir })
  if not roots then
    roots = { vim.env.TMPDIR, "/tmp" }
  end

  local resolved = {}
  for _, root in ipairs(roots) do
    if root and root ~= "" then
      table.insert(resolved, resolve(root))
    end
  end
  return resolved
end

---Resolve the lone prompt file this Neovim was launched to edit, if any.
---
---Deliberately weaker than `M.detect`: it does not require a captured
---closeout. The closeout split is a bonus, but the window's cwd has to stay on
---the agent's repo whether or not the capture succeeded — otherwise `@`
---completion, `:e` and fzf-lua all point at the temp tree.
---@param opts? { args?: string[], tmpdir?: string, tmpdirs?: string[], agent?: boolean, env?: table<string, string> }
---@return string? file Resolved path of the prompt file
function M.detect_prompt_file(opts)
  opts = opts or {}

  if not launched_by_agent(opts) then
    return nil
  end

  local args = opts.args or vim.fn.argv()
  if type(args) ~= "table" or #args ~= 1 or args[1] == "" then
    return nil
  end

  local roots = tmp_roots(opts)
  if #roots == 0 then
    return nil
  end

  -- Resolve both sides: on macOS $TMPDIR is a symlinked /var/folders path and
  -- /tmp is a symlink to /private/tmp, so an unresolved compare would reject
  -- every real prompt file.
  local file = resolve(vim.fn.fnamemodify(args[1], ":p"))
  for _, root in ipairs(roots) do
    if is_under(root, file) then
      return file
    end
  end
  return nil
end

---@class AgentPrompt.Target
---@field file string Resolved path of the prompt file
---@field closeout string Path of the captured closeout
---@field seed string? Path of the captured ready-to-paste block

---Decide whether this Neovim can show the closeout beside the prompt.
---
---`$AGENT_CLOSEOUT_FILE` is the load-bearing signal: only the shim sets it, and
---only after a closeout was actually extracted.
---@param opts? { args?: string[], closeout?: string, seed?: string, tmpdir?: string, tmpdirs?: string[], agent?: boolean, env?: table<string, string> }
---@return AgentPrompt.Target?
function M.detect(opts)
  opts = opts or {}

  local closeout = opts.closeout or vim.env.AGENT_CLOSEOUT_FILE
  if not closeout or closeout == "" or vim.fn.filereadable(closeout) ~= 1 then
    return nil
  end

  -- The shim only exports a closeout for a real agent launch, so an explicit
  -- one stands in for the inherited agent variables a spec cannot rely on.
  local file = M.detect_prompt_file(vim.tbl_extend("keep", opts, {
    agent = opts.closeout ~= nil or launched_by_agent(opts),
  }))
  if not file then
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

  -- Bottom by default: a prompt is written in long lines, and a right-hand
  -- split halves the width available for both it and the closeout. Set
  -- `vim.g.agent_prompt_split` to "right" for the side-by-side layout.
  local placement = vim.g.agent_prompt_split
  if placement ~= "right" and placement ~= "below" then
    placement = "below"
  end

  local win = vim.api.nvim_open_win(buf, false, {
    split = placement,
    win = 0,
  })
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].wrap = true
  vim.wo[win].spell = false
  -- Pin whichever dimension the placement owns, so later splits do not squeeze
  -- the reference out of shape.
  if placement == "right" then
    vim.wo[win].winfixwidth = true
  else
    vim.wo[win].winfixheight = true
  end

  -- Read-only reference, but still a real window: yankable, searchable and
  -- scrollable on its own.
  vim.keymap.set("n", "q", "<C-w>c", { buf = buf, nowait = true })

  vim.w[win].agent_prompt_placement = placement
  return win
end

---Give the closeout its share of the frame back after the pane is resized.
---
---A Herdr split (Alt+s and friends) shrinks the pane under Neovim.
---`winfix{height,width}` holds the closeout steady only while the rows or
---columns last; past that Neovim shrinks it anyway, and when the pane grows
---back the fix that protected it is exactly what stops it growing again. So
---record the share it opened with and restore that share on every resize.
---@param prompt_win integer
---@param closeout_win integer
local function keep_share(prompt_win, closeout_win)
  local vertical = vim.w[closeout_win].agent_prompt_placement == "right"
  local get = vertical and vim.api.nvim_win_get_width
    or vim.api.nvim_win_get_height
  local set = vertical
      and function(win, n)
        vim.api.nvim_win_resize(win, n, -1)
      end
    or function(win, n)
      vim.api.nvim_win_resize(win, -1, n)
    end

  local closeout_buf = vim.api.nvim_win_get_buf(closeout_win)
  local total = get(closeout_win) + get(prompt_win)
  if total < 2 then
    return
  end
  local share = get(closeout_win) / total

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup(
      "AgentPromptCloseoutSize" .. closeout_win,
      { clear = true }
    ),
    callback = function()
      -- Window ids are recycled; a closeout showing another buffer is a
      -- different window, and the autocmd has outlived its purpose.
      if
        not vim.api.nvim_win_is_valid(closeout_win)
        or not vim.api.nvim_win_is_valid(prompt_win)
        or vim.api.nvim_win_get_buf(closeout_win) ~= closeout_buf
      then
        return true
      end
      -- Deferred: Neovim redistributes rows after VimResized, and a size set
      -- from inside the callback is overwritten by that pass.
      vim.schedule(function()
        if
          not vim.api.nvim_win_is_valid(closeout_win)
          or not vim.api.nvim_win_is_valid(prompt_win)
        then
          return
        end
        local frame = get(closeout_win) + get(prompt_win)
        pcall(set, closeout_win, math.max(1, math.floor(frame * share + 0.5)))
      end)
    end,
  })
end

---Tie the closeout window's lifetime to the prompt window's.
---
---The closeout is a reference, not a second document: `:wq` on the prompt means
---"hand this back to the agent", and leaving the reference behind keeps Neovim
---on screen for a window the user is done with. Closing the prompt therefore
---closes the closeout, and with it the last window, which returns the pane to
---the agent.
---@param prompt_win integer
---@param closeout_win integer
local function close_closeout_with_prompt(prompt_win, closeout_win)
  -- Window ids are recycled, so identity is checked against the buffer this
  -- window was opened for, not the handle alone.
  local closeout_buf = vim.api.nvim_win_get_buf(closeout_win)
  local prompt_buf = vim.api.nvim_win_get_buf(prompt_win)
  local group = vim.api.nvim_create_augroup(
    "AgentPromptCloseout" .. prompt_win,
    { clear = true }
  )

  local function drop_closeout()
    if
      not vim.api.nvim_win_is_valid(closeout_win)
      or vim.api.nvim_win_get_buf(closeout_win) ~= closeout_buf
    then
      return false
    end
    return (pcall(vim.api.nvim_win_close, closeout_win, true))
  end

  -- QuitPre runs before the window is taken down, so dropping the reference
  -- here leaves `:q`/`:wq`/`ZZ` quitting the last window: Neovim exits on that
  -- command itself instead of surviving into a scheduled callback with the
  -- closeout alone on screen.
  vim.api.nvim_create_autocmd("QuitPre", {
    group = group,
    callback = function()
      if vim.api.nvim_get_current_win() ~= prompt_win then
        return
      end
      -- An unwritten prompt is the user's text. `:q` would hide rather than
      -- discard it, so leave the layout alone and let Vim's own rules apply.
      if vim.bo[prompt_buf].modified then
        return
      end
      drop_closeout()
    end,
  })

  -- Backstop for the closes QuitPre never sees: `:close`, `nvim_win_close`, a
  -- window closed by something else entirely.
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    pattern = tostring(prompt_win),
    once = true,
    callback = function()
      -- Deferred: WinClosed fires while the window is still being torn down,
      -- so closing another one from inside the callback is refused.
      vim.schedule(function()
        -- Floats -- notifications, pickers, diagnostics -- are counted by
        -- `nvim_tabpage_list_wins` but cannot hold the pane open. Counting them
        -- as company left the closeout as the last real window with no path to
        -- quitting, which is exactly the reference stranded on screen.
        local real = 0
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if vim.api.nvim_win_get_config(win).relative == "" then
            real = real + 1
          end
        end
        if real <= 1 and vim.api.nvim_win_is_valid(closeout_win) then
          -- Nothing left to close the reference *into*. Forcing the quit is
          -- safe only because a modified prompt was excluded above; here it
          -- may still be modified, so let Vim refuse rather than discard it.
          local bang = not vim.bo[prompt_buf].modified
          pcall(vim.cmd.quitall, { bang = bang, mods = { silent = true } })
          return
        end
        drop_closeout()
      end)
    end,
  })
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
  M.anchor_cwd(prompt_win, cwd)

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
    close_closeout_with_prompt(prompt_win, closeout_win)
    keep_share(prompt_win, closeout_win)
    vim.api.nvim_set_current_win(prompt_win)
  end

  return closeout_win
end

---Pin a window to the agent's cwd. The window, not the process: `@`
---completion, `:e`, `:grep` and fzf-lua all read the window's cwd, and without
---this they point at the temp tree the prompt file lives in.
---@param win integer
---@param cwd? string Defaults to Neovim's startup cwd
function M.anchor_cwd(win, cwd)
  cwd = cwd or startup_cwd
  if not cwd or vim.fn.isdirectory(cwd) ~= 1 then
    return
  end
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  vim.api.nvim_win_call(win, function()
    pcall(vim.cmd.lcd, {
      cwd,
      mods = { silent = true, emsg_silent = true },
    })
  end)
end

---Exempt a buffer from the `auto_cwd` autocmd, which would otherwise `lcd` the
---prompt window to the prompt file's directory under the agent's temp root.
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
  -- Keyed on the prompt file alone, not on a captured closeout: the capture is
  -- best-effort (no herdr, no closeout in the scrollback, an agent whose first
  -- turn has nothing to quote), and losing it must not also lose the cwd.
  local file = M.detect_prompt_file()
  if not file then
    return
  end

  local group = vim.api.nvim_create_augroup("agent_prompt", {})

  -- The mark has to land before the first BufEnter, or `auto_cwd` moves the
  -- window before anything can opt out.
  vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
    group = group,
    pattern = file,
    callback = function(args)
      M.mark(args.buf)
    end,
  })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    once = true,
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      if resolve(vim.api.nvim_buf_get_name(buf)) ~= file then
        return
      end

      local target = M.detect()
      if target then
        M.open(target)
        return
      end

      -- No closeout to show: the prompt keeps the whole window, still rooted
      -- on the repo the agent was launched from.
      M.mark(buf)
      M.anchor_cwd(vim.api.nvim_get_current_win())

      -- Say so. A silent fall-through is identical on screen to the feature
      -- being broken, and that ambiguity has cost real debugging time: the
      -- usual cause is simply a pane whose agent has not printed a closeout
      -- yet. Deferred so it survives startup's message clearing.
      local reason = vim.env.AGENT_PROMPT_REASON
      vim.schedule(function()
        vim.notify(
          "agent-prompt: no closeout — "
            .. (reason ~= nil and reason ~= "" and reason or "the shim did not run"),
          vim.log.levels.INFO
        )
      end)
    end,
  })
end

return M
