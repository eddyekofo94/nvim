local M = {}
local check_duplicates = require("utils.duplicates").check_duplicates
local cmd = vim.api.nvim_create_user_command

cmd("Reconfuse", function()
  _G.confusing_maps = true
end, { desc = "Remove confusing map", force = true })

cmd("Unconfuse", function()
  _G.confusing_maps = false
end, { desc = "Remove confusing map", force = true })

M.nxo = { "n", "x", "o" }

-- move over a closing element in insert mode
M.escapePair = function()
  local closers = { ")", "]", "}", ">", "'", '"', "`", "," }
  local line = vim.api.nvim_get_current_line()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local after = line:sub(col + 1, -1)
  local closer_col = #after + 1
  local closer_i = nil
  for i, closer in ipairs(closers) do
    local cur_index, _ = after:find(closer)
    if cur_index and (cur_index < closer_col) then
      closer_col = cur_index
      closer_i = i
    end
  end
  if closer_i then
    vim.api.nvim_win_set_cursor(0, { row, col + closer_col })
  else
    vim.api.nvim_win_set_cursor(0, { row, col + 1 })
  end
end

--- If you don't pass the modes, it is normal and execute
-- function M.set_keymap(modes, lhs, rhs, opts)
--   if type(opts) == "string" then
--     opts = { desc = opts }
--   end
--   vim.keymap.set(modes, lhs, rhs, opts)
--   -- check_duplicates(modes, lhs, description)
-- end

function M.set_keymap(modes, input, output, opts)
  -- local options = vim.tbl_deep_extend("force", { noremap = true, silent = true }, opts or {})
  local description = ""
  local options = { desc = description, noremap = true, silent = true }

  if type(opts) == "table" then
    options = vim.tbl_deep_extend("force", options, opts or {})
  elseif type(opts) == "string" then
    description = opts
    opts = { desc = opts }
    options = vim.tbl_deep_extend("force", options, opts or {})
  end

  vim.keymap.set(modes, input, output, options)
  check_duplicates(modes, input, description)
end

function M.set_leader_keymap(input, output, options)
  M.set_keymap({ "n", "x" }, "<leader>" .. input, output, options)
end

function M.set_n_keymap(key, rhs, opts)
  M.set_keymap("n", key, rhs, opts)
end

function M.set_buf_keymap(mode, key, rhs, opts)
  local options = { buffer = 0, noremap = true, silent = true }
  if type(opts) == "string" then
    opts = { desc = opts }
  end
  options = vim.tbl_deep_extend("force", options, opts)
  M.set_keymap(mode, key, rhs, options)
end

---Set abbreviation that only expand when the trigger is at the position of
---a command
---@param trig string
---@param command string
---@param opts table?
-- function M.command_abbrev(trig, command, opts)
--   vim.keymap.set("ca", trig, function()
--     return vim.fn.getcmdcompltype() == "command" and command or trig
--   end, vim.tbl_deep_extend("keep", { expr = true }, opts or {}))
-- end

---Set abbreviation that only expand when the trigger is at the position of
---a command
---@param trig string|{ [1]: string, [2]: string }
---@param command string
---@param opts table?
function M.command_abbrev(trig, command, opts)
  -- Map a range, first one if command short name,
  -- second one if command full name
  if type(trig) == "table" then
    local trig_short = trig[1]
    local trig_full = trig[2]
    for i = #trig_short, #trig_full do
      local cmd_part = trig_full:sub(1, i)
      M.command_abbrev(cmd_part, command)
    end
    return
  end
  vim.keymap.set("ca", trig, function()
    return vim.fn.getcmdcompltype() == "command" and command or trig
  end, vim.tbl_deep_extend("keep", { expr = true }, opts or {}))
end

---Set keymap that only expand when the trigger is at the position of
---a command
---@param trig string
---@param command string
---@param opts table?
function M.command_map(trig, command, opts)
  vim.keymap.set("c", trig, function()
    return vim.fn.getcmdcompltype() == "command" and command or trig
  end, vim.tbl_deep_extend("keep", { expr = true }, opts or {}))
end

---@class keymap_def_t
---@field lhs string
---@field lhsraw string
---@field rhs string?
---@field callback function?
---@field expr boolean?
---@field desc string?
---@field noremap boolean?
---@field script boolean?
---@field silent boolean?
---@field nowait boolean?
---@field buffer boolean?
---@field replace_keycodes boolean?

---Get keymap definition
---@param mode string
---@param lhs string
---@return keymap_def_t
function M.get(mode, lhs)
  local lhs_keycode = vim.keycode(lhs)
  for _, map in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
    if vim.keycode(map.lhs) == lhs_keycode then
      return {
        lhs = map.lhs,
        rhs = map.rhs,
        expr = map.expr == 1,
        callback = map.callback,
        desc = map.desc,
        noremap = map.noremap == 1,
        script = map.script == 1,
        silent = map.silent == 1,
        nowait = map.nowait == 1,
        buffer = true,
        replace_keycodes = map.replace_keycodes == 1,
      }
    end
  end
  for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
    if vim.keycode(map.lhs) == lhs_keycode then
      return {
        lhs = map.lhs,
        rhs = map.rhs or "",
        expr = map.expr == 1,
        callback = map.callback,
        desc = map.desc,
        noremap = map.noremap == 1,
        script = map.script == 1,
        silent = map.silent == 1,
        nowait = map.nowait == 1,
        buffer = false,
        replace_keycodes = map.replace_keycodes == 1,
      }
    end
  end
  return {
    lhs = lhs,
    rhs = lhs,
    expr = false,
    noremap = true,
    script = false,
    silent = true,
    nowait = false,
    buffer = false,
    replace_keycodes = true,
  }
end

---@param def keymap_def_t
---@return function
function M.fallback_fn(def)
  local modes = def.noremap and "in" or "im"
  ---@param keys string
  ---@return nil
  local function feed(keys)
    local keycode = vim.keycode(keys)
    local keyseq = vim.v.count > 0 and vim.v.count .. keycode or keycode
    vim.api.nvim_feedkeys(keyseq, modes, false)
  end
  if not def.expr then
    return def.callback or function()
      feed(def.rhs)
    end
  end
  if def.callback then
    return function()
      feed(def.callback())
    end
  else
    -- Escape rhs to avoid nvim_eval() interpreting
    -- special characters
    local rhs = vim.fn.escape(def.rhs, "\\")
    return function()
      feed(vim.api.nvim_eval(rhs))
    end
  end
end

---Amend keymap
---Caveat: currently cannot amend keymap with <Cmd>...<CR> rhs
---@param modes string[]|string
---@param lhs string
---@param rhs function(fallback: function)
---@param opts table?
---@return nil
function M.amend(modes, lhs, rhs, opts)
  modes = type(modes) ~= "table" and { modes } or modes --[=[@as string[]]=]
  for _, mode in ipairs(modes) do
    local fallback = M.fallback_fn(M.get(mode, lhs))
    vim.keymap.set(mode, lhs, function()
      rhs(fallback)
    end, opts)
  end
end

---Wrap a function so that it repeats the original function multiple times
---according to v:count or v:count1
---@generic T
---@param fn fun(): T?
---@param count? 0|1 count given for the last normal mode command, see `:h v:count` or `:h v:count1`, default to 1
---@return fun(): T[]
function M.count_wrap(fn, count)
  return function()
    if count == 0 and vim.v.count0 == 0 then
      return {}
    end
    local result = {}
    for _ = 1, vim.v.count1 do
      vim.list_extend(result, { fn() })
    end
    return unpack(result)
  end
end

--- Table based API for setting keybindings
---@param map_table table A nested table where the first key is the vim mode, the second key is the key to map, and the value is the function to set the mapping to
---@param base? table A base set of options to set on every keybinding
function M.set_mappings(map_table, base)
  -- iterate over the first keys for each mode
  base = base or {}
  for mode, maps in pairs(map_table) do
    -- iterate over each keybinding set in the current mode
    for keymap, options in pairs(maps) do
      -- build the options for the command accordingly
      if options then
        local cmd = options
        local keymap_opts = base
        if type(options) == "table" then
          cmd = options[1]
          keymap_opts = vim.tbl_deep_extend("force", keymap_opts, options)
          keymap_opts[1] = nil
        end
        if not cmd or keymap_opts.name then -- if which-key mapping, queue it
          if not keymap_opts.name then
            keymap_opts.name = keymap_opts.desc
          end
          if not M.which_key_queue then
            M.which_key_queue = {}
          end
          if not M.which_key_queue[mode] then
            M.which_key_queue[mode] = {}
          end
          M.which_key_queue[mode][keymap] = keymap_opts
        else -- if not which-key mapping, set it
          vim.keymap.set(mode, keymap, cmd, keymap_opts)
        end
      end
    end
  end
  if package.loaded["which-key"] then
    M.which_key_register()
  end -- if which-key is loaded already, register
end

--- Register queued which-key mappings
function M.which_key_register()
  if M.which_key_queue then
    local wk_avail, wk = pcall(require, "which-key")
    if wk_avail then
      for mode, registration in pairs(M.which_key_queue) do
        wk.register(registration, { mode = mode })
      end
      M.which_key_queue = nil
    end
  end
end

function M.empty_map_table()
  local maps = {}
  for _, mode in ipairs { "", "n", "v", "x", "s", "o", "!", "i", "l", "c", "t", "leader" } do
    maps[mode] = {}
  end
  if vim.fn.has "nvim-0.10.0" == 1 then
    for _, abbr_mode in ipairs { "ia", "ca", "!a" } do
      maps[abbr_mode] = {}
    end
  end
  return maps
end

M.confusing = function(modes, k, v, opts)
  _G.confusing_maps_set = _G.confusing_maps_set or {}
  _G.confusing_maps_set[k] = { map = vim.inspect(v), desc = opts.desc }
  if type(opts.desc) == "string" then
    opts.desc = "confusing: " .. opts.desc
  end
  vim.keymap.set(modes, k, function()
    if _G.confusing_maps ~= false then
      if type(v) == "function" then
        local ok, val = pcall(v)
        return opts.expr and ok and val or ""
      else
        return v
      end
    else
      return k
    end
  end, opts)
end

return M
