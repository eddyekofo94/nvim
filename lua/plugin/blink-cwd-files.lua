---`@`-triggered project file tagging for blink.cmp, in buffers and cmdline.
---
---Blink's builtin `path` source can only ever list a single directory: its
---`dirname()` cuts the line at the last `/` and reads that one folder, so
---`lua/co` can never reach `lua/core/keymaps.lua`. This source takes over for
---arguments starting with `@`, walking the whole project tree and matching
---against the full relative path.
---
---`@` is the trigger, in a buffer and in the cmdline alike, matching how files
---are tagged in Claude, Codex and Pi. It never collides with real text, so `/`,
---`./` and `~/` keep blink's ordinary one-directory `path` behaviour.
---
---Blink's own fuzzy matcher cannot do the matching for us: its keyword regex
---stops at `/` and `.` (`fuzzy.get_keyword_range()` lives in Rust and takes no
---character class), so `@lua/core/key` would be matched as just `key`. We rank
---with `matchfuzzy()` instead and hand blink a `filterText` equal to the keyword
---it computed, so every item scores identically and `sortText` preserves our
---order rather than blink re-filtering our results away.
local M = {}

---Entries kept per directory tree. Bounded so a scan of a huge tree can't grow
---without limit; the fuzzy pass runs over this list on every keystroke.
local MAX_ENTRIES = 20000

---Entries handed to blink. The menu shows a handful, but a larger list keeps
---scrolling useful without paying for 20k table entries per keystroke.
local MAX_ITEMS = 200

---How long a tree listing stays fresh, in milliseconds. Long enough that typing
---a path never re-runs the scan, short enough that new files show up quickly.
local CACHE_TTL_MS = 5000

---Ordered by preference. Both respect `.gitignore`, which is what makes this
---usable in a home directory or a monorepo.
local SCANNERS = {
  { "fd", "--hidden", "--type", "f", "--type", "d", "--exclude", ".git" },
  { "rg", "--files", "--hidden", "--glob", "!.git" },
}

---@type table<string, { entries: string[]?, at: integer, running: boolean, waiters: fun(entries: string[])[] }>
local cache = {}

---@return string[]?
local function scanner()
  for _, cmd in ipairs(SCANNERS) do
    if vim.fn.executable(cmd[1]) == 1 then
      return cmd
    end
  end
end

---Last resort when neither `fd` nor `rg` is installed. Depth limited because an
---unbounded pure-Lua walk of a large tree blocks the UI.
---@param cwd string
---@return string[]
local function walk(cwd)
  local entries = {}
  for name, kind in
    vim.fs.dir(cwd, {
      depth = 6,
      skip = function(dir)
        return dir ~= ".git"
      end,
    })
  do
    entries[#entries + 1] = kind == "directory" and name .. "/" or name
    if #entries >= MAX_ENTRIES then
      break
    end
  end
  return entries
end

---@param cwd string
---@param done fun(entries: string[])
local function scan(cwd, done)
  local entry = cache[cwd]
  if
    entry
    and entry.entries
    and (vim.uv.now() - entry.at) < CACHE_TTL_MS
    and not entry.running
  then
    return done(entry.entries)
  end

  entry = entry or { at = 0, running = false, waiters = {} }
  cache[cwd] = entry
  entry.waiters[#entry.waiters + 1] = done
  if entry.running then
    return
  end

  ---@param entries string[]
  local function finish(entries)
    entry.entries = entries
    entry.at = vim.uv.now()
    entry.running = false

    local waiters = entry.waiters
    entry.waiters = {}
    for _, waiter in ipairs(waiters) do
      waiter(entries)
    end
  end

  local cmd = scanner()
  if not cmd then
    return finish(walk(cwd))
  end

  entry.running = true
  vim.system(cmd, { cwd = cwd, text = true }, function(out)
    local entries = {}
    for line in (out.stdout or ""):gmatch("[^\n]+") do
      entries[#entries + 1] = line
      if #entries >= MAX_ENTRIES then
        break
      end
    end
    vim.schedule(function()
      finish(entries)
    end)
  end)
end

---Split the line the way the cmdline does: on whitespace that isn't backslash
---escaped, so `:e my\ file` stays one argument.
---@param line string
---@param col integer 0-indexed cursor offset into `line`
---@return string arg Text of the argument from its start up to the cursor
---@return integer start 0-indexed offset of the argument's first character
function M.argument_at(line, col)
  local before = line:sub(1, col)
  local start = 0
  local i = 1
  while i <= #before do
    local char = before:sub(i, i)
    if char == "\\" then
      i = i + 2
    elseif char:match("%s") then
      start = i
      i = i + 1
    else
      i = i + 1
    end
  end
  return before:sub(start + 1), start
end

---The fuzzy query inside `arg`, or nil when `arg` isn't ours to complete.
---@param arg string
---@return string?
function M.query(arg)
  if vim.startswith(arg, "@") then
    return arg:sub(2)
  end
end

---Tree searched by a project-wide query. The git root when there is one, so a
---search from a subdirectory still covers the whole repo.
---@return string
function M.root()
  return vim.fs.root(0, ".git") or vim.fn.getcwd()
end

---Text to insert for an absolute path: `./`-prefixed when under the cwd, a
---`~`-shortened absolute path otherwise. The `@` is consumed, so what lands on
---the line is a real path. Only the cmdline wants `fnameescape()` — in a buffer
---the literal path is what belongs there.
---@param abs string
---@param cmdline? boolean Defaults to whether the cmdline is currently open
---@return string
function M.insert_text(abs, cmdline)
  if cmdline == nil then
    cmdline = vim.fn.getcmdtype() ~= ""
  end

  local relative = vim.fn.fnamemodify(abs, ":.")
  local path = relative ~= abs and "./" .. relative
    or vim.fn.fnamemodify(abs, ":~")
  return cmdline and vim.fn.fnameescape(path) or path
end

---Whether the cursor sits inside an `@` argument, in either an Ex cmdline or a
---buffer. Drives both the source's `enabled()` and the source lists, so blink's
---one-directory `path` source steps aside instead of duplicating entries.
---@return boolean
function M.is_active()
  local cmdtype = vim.fn.getcmdtype()
  local line, col
  if cmdtype ~= "" then
    if cmdtype ~= ":" then
      return false
    end
    line, col = vim.fn.getcmdline(), vim.fn.getcmdpos() - 1
  else
    line = vim.api.nvim_get_current_line()
    col = vim.api.nvim_win_get_cursor(0)[2]
  end

  return M.query(M.argument_at(line, col)) ~= nil
end

---Drop cached listings. Exposed for tests and for picking up a fresh tree.
function M.invalidate()
  cache = {}
end

local source = {}
source.__index = source

function M.new(opts)
  return setmetatable({ opts = opts or {} }, source)
end

-- Blink calls these with `:`, so the dropped first argument is `self`. Declared
-- without it because none of them need instance state.
function source.enabled()
  return M.is_active()
end

function source.get_trigger_characters()
  return { "@", "/", "-", "_", "." }
end

---@param context blink.cmp.Context
---@param callback fun(response?: table)
---@return fun()?
function source.get_completions(_, context, callback)
  local cmdline = context.mode == "cmdline" or context.mode == "cmdwin"
  local arg, arg_start = M.argument_at(context.line, context.pos.col)
  local query = M.query(arg)
  if not query then
    callback()
    return
  end

  local root = M.root()
  local cancelled = false

  scan(root, function(entries)
    if cancelled then
      return
    end

    local matches = entries
    if query ~= "" then
      local ok, fuzzy_matches = pcall(vim.fn.matchfuzzy, entries, query)
      matches = ok and fuzzy_matches or {}
    end

    -- Pin `filterText` to blink's keyword so every item is an exact match: the
    -- keyword stops at `/`, so anything else would let blink re-filter (and
    -- reorder) the ranking we just computed over the full path.
    local fuzzy = require("blink.cmp.fuzzy")
    local keyword_start, keyword_end =
      fuzzy.get_keyword_range(context.line, context.pos.col, false)
    local keyword = context.line:sub(keyword_start + 1, keyword_end)

    -- Accepting replaces the whole argument, including the part right of the
    -- cursor, so editing mid-path doesn't leave a stale tail behind.
    local tail = context.line:sub(context.pos.col + 1):match("^%S*") or ""

    local kinds = require("blink.cmp.types").CompletionItemKind
    local items = {}
    for idx = 1, math.min(#matches, MAX_ITEMS) do
      local rel = matches[idx]:gsub("/$", "")
      local abs = vim.fs.joinpath(root, rel)
      local is_dir = vim.endswith(matches[idx], "/")
        or vim.fn.isdirectory(abs) == 1
      local suffix = is_dir and "/" or ""

      items[idx] = {
        label = rel .. suffix,
        filterText = keyword,
        sortText = string.format("%06d", idx),
        kind = is_dir and kinds.Folder or kinds.File,
        textEdit = {
          newText = M.insert_text(abs, cmdline) .. suffix,
          insert = {
            start = { line = context.pos.row, character = arg_start },
            ["end"] = { line = context.pos.row, character = context.pos.col },
          },
          replace = {
            start = { line = context.pos.row, character = arg_start },
            ["end"] = {
              line = context.pos.row,
              character = context.pos.col + #tail,
            },
          },
        },
      }
    end

    callback({
      -- Re-run on every keystroke: `filterText` is pinned to the current
      -- keyword, so a cached list stops matching the moment the keyword changes.
      is_incomplete_backward = true,
      is_incomplete_forward = true,
      items = items,
    })
  end)

  return function()
    cancelled = true
  end
end

return M
