-- 1. Initialize the module table FIRST
local M = {}

local Keymap = {}
Keymap.__index = Keymap

-- Group storage
local registry = {}

M.nxo = { 'n', 'x', 'o' }

---Get keymap definition
---@param mode string
---@param lhs string
---@return key.def
function M.get(mode, lhs)
  local lhs_keycode = vim.keycode(lhs)

  -- Check buffer-local first, then global
  local map = vim
    .iter({
      { scope = vim.api.nvim_buf_get_keymap(0, mode), is_buf = true },
      { scope = vim.api.nvim_get_keymap(mode), is_buf = false },
    })
    :map(function(item)
      return vim.iter(item.scope):find(function(m)
        return vim.keycode(m.lhs) == lhs_keycode
      end),
        item.is_buf
    end)
    :find(function(m)
      return m ~= nil
    end)

  if map then
    return {
      lhs = map.lhs,
      rhs = map.rhs or '',
      expr = map.expr == 1,
      callback = map.callback,
      desc = map.desc,
      noremap = map.noremap == 1,
      silent = map.silent == 1,
      nowait = map.nowait == 1,
      buffer = true, -- we adjust this based on 'is_buf' logic if needed
      replace_keycodes = map.replace_keycodes == 1,
    }
  end

  -- Return default identity mapping (fallback to self)
  return { lhs = lhs, rhs = lhs, noremap = true, buffer = false }
end

local warned_keys = {}
local conflict_count = 0
---Set keymaps, don't override existing keymaps unless `opts.unique` is false
---@param modes string|string[] mode short-name
---@param lhs string left-hand side of the mapping
---@param rhs string|function right-hand side of the mapping
---@param opts? vim.keymap.set.Opts
---@return nil
function M.map(modes, lhs, rhs, opts)
  -- 1. Handle "string as desc" logic
  local final_opts = {}
  if type(opts) == 'string' then
    final_opts = { desc = opts }
  elseif type(opts) == 'table' then
    final_opts = opts
  end

  final_opts = vim.tbl_extend('keep', final_opts, {
    noremap = true,
    silent = true,
  })

  -- 2. Duplicate Check
  local mode_list = type(modes) == 'table' and modes or { modes }

  for _, mode in ipairs(mode_list) do
    local existing = vim.fn.maparg(lhs, mode, false, true)

    if type(existing) == 'table' and next(existing) ~= nil then
      local conflict_id = mode .. '_' .. lhs

      -- Check if it's a real conflict or just a duplicate definition
      -- We check RHS (action) and Description
      local is_same_rhs = existing.rhs == rhs
      local is_same_desc = existing.desc == final_opts.desc

      if
        not (is_same_rhs or is_same_desc) and not warned_keys[conflict_id]
      then
        conflict_count = conflict_count + 1

        local path = existing.sid > 0
            and vim.fn.expand('<script:' .. existing.sid .. '>')
          or 'Internal/Built-in'
        local plugin_name = path:match('lazy/([^/]+)') or 'User Config'
        local action = (existing.rhs and existing.rhs ~= '') and existing.rhs
          or 'Lua function'
        local description = existing.desc or 'No description'

        warned_keys[conflict_id] = {
          lhs = lhs,
          mode = mode,
          plugin = plugin_name,
          path = path,
          line = existing.lnum or '?',
          action = action,
          desc = description,
        }

        vim.notify(
          string.format('Conflict #%d: [%s]', conflict_count, lhs),
          vim.log.levels.WARN
        )
      end
    end
  end

  -- 3. Execute the actual mapping
  vim.keymap.set(modes, lhs, rhs, final_opts)
end

-- 4. The Summation Report (Horizontal Split)
function M.get_conflicts()
  if conflict_count == 0 then
    vim.notify('✨ No keymap conflicts detected!', vim.log.levels.INFO)
    return
  end

  local report = {
    '📊 KEYMAP CONFLICT AUDIT',
    'Total unique collisions: ' .. conflict_count,
    '',
  }

  for _, data in pairs(warned_keys) do
    table.insert(report, string.format('🔑 [%s] %s', data.mode, data.lhs))
    table.insert(report, string.format('   📦 Plugin: %s', data.plugin))
    table.insert(
      report,
      string.format('   📍 Source: %s:%s', data.path, data.line)
    )
    table.insert(report, string.format('   ⚙️  Action: %s', data.action))
    table.insert(report, string.format('   📝 Desc:   %s', data.desc))
    table.insert(report, '   ' .. string.rep('─', 40))
  end

  -- Create buffer and set lines
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, report)

  -- Open a horizontal split at the bottom
  vim.cmd('botright split')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  -- Set some window options for the report
  vim.api.nvim_set_option_value('number', false, { win = win })
  vim.api.nvim_set_option_value('relativenumber', false, { win = win })
  vim.api.nvim_set_option_value('winfixheight', true, { win = win })
  vim.api.nvim_win_set_height(win, 15) -- Adjust height as needed

  -- Set buffer to scratch type so it's not saved
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
  vim.api.nvim_set_option_value('filetype', 'markdown', { buf = buf })
end

function M.check_conflicts()
  local modes = { 'n', 'i', 'c', 'v', 'x', 'o', 's', 't' }
  local all_keymaps = {}

  for _, mode in ipairs(modes) do
    local global_maps = vim.api.nvim_get_keymap(mode)
    local buf_maps = vim.api.nvim_buf_get_keymap(0, mode)

    for _, map in ipairs(global_maps) do
      local key = vim.keycode(map.lhs)
      if key ~= '' and map.rhs ~= '' and map.rhs ~= map.lhs then
        all_keymaps[key] = all_keymaps[key] or {}
        table.insert(all_keymaps[key], {
          mode = mode,
          rhs = map.rhs,
          desc = map.desc,
          source = 'global',
        })
      end
    end

    for _, map in ipairs(buf_maps) do
      local key = vim.keycode(map.lhs)
      if key ~= '' and map.rhs ~= '' and map.rhs ~= map.lhs then
        all_keymaps[key] = all_keymaps[key] or {}
        table.insert(all_keymaps[key], {
          mode = mode,
          rhs = map.rhs,
          desc = map.desc,
          source = 'buffer',
        })
      end
    end
  end

  warned_keys = {}
  conflict_count = 0

  for key, mappings in pairs(all_keymaps) do
    if #mappings > 1 then
      for i = 1, #mappings do
        for j = i + 1, #mappings do
          local m1, m2 = mappings[i], mappings[j]
          if m1.rhs ~= m2.rhs or m1.desc ~= m2.desc then
            local conflict_id = key .. '_' .. m1.mode .. '_' .. m2.mode
            if not warned_keys[conflict_id] then
              conflict_count = conflict_count + 1
              warned_keys[conflict_id] = {
                lhs = key,
                mode = m1.mode .. '/' .. m2.mode,
                plugin = 'Multiple sources',
                path = m1.source .. ' & ' .. m2.source,
                line = '?',
                action = m1.rhs,
                desc = m1.desc or 'No description',
              }
              vim.notify(
                string.format('Conflict #%d: [%s]', conflict_count, key),
                vim.log.levels.WARN
              )
            end
          end
        end
      end
    end
  end

  if conflict_count > 0 then
    vim.notify(
      string.format(
        '⚠️  %d keymap conflict(s) detected. Run :check_conflicts to view details.',
        conflict_count
      ),
      vim.log.levels.WARN
    )
  else
    vim.notify('✨ No keymap conflicts detected!', vim.log.levels.INFO)
  end
end

vim.api.nvim_create_user_command('CheckConflicts', function()
  M.get_conflicts()
end, { desc = 'Show keymap conflicts report' })

-- set normal map
function M.nmap(key, rhs, opts)
  M.map('n', key, rhs, opts)
end

-- Set leader map
function M.lmap(input, output, options)
  M.map({ 'n', 'x' }, '<leader>' .. input, output, options)
end

function Keymap.new(mode, lhs, rhs, opts)
  local self = setmetatable({}, Keymap)

  -- Internalize data for chaining and re-execution
  self.mode = mode
  self.lhs = lhs
  self.rhs = rhs
  self.opts = type(opts) == 'string' and { desc = opts } or opts or {}

  self.action = function(bufnr)
    -- 1. Create a clean copy of options for Neovim
    local nvim_opts = vim.tbl_extend('force', {}, self.opts)

    -- 2. REMOVE the custom 'group' key so Neovim doesn't see it
    nvim_opts.group = nil

    -- 3. Handle buffer-locality
    if bufnr then
      nvim_opts.buffer = bufnr
    end

    if self.mode == '!a' then
      -- Abbreviations handling
      local prefix = bufnr and 'inoreabbrev <buffer>' or 'inoreabbrev'
      local c_prefix = bufnr and 'cnoreabbrev <buffer>' or 'cnoreabbrev'
      vim.cmd(string.format('%s %s %s', prefix, self.lhs, self.rhs))
      vim.cmd(string.format('%s %s %s', c_prefix, self.lhs, self.rhs))
    else
      -- 4. Pass the CLEANED options to Neovim
      M.map(self.mode, self.lhs, self.rhs, nvim_opts)
    end
  end
  -- Registration
  if self.opts.group then
    registry[self.opts.group] = registry[self.opts.group] or {}
    table.insert(registry[self.opts.group], self)
  end

  return self
end

-- Execute and return self to allow chaining
function Keymap:execute()
  self.action()
  return self
end

-- Bind (execute) and then return the NEXT mapping to continue the chain
function Keymap:bind(nextMapping)
  self.action()
  return nextMapping
end

-- Start a chain
function M.set(mode, lhs, rhs, opts)
  return Keymap.new(mode, lhs, rhs, opts)
end

-- Module level execution
function M.execute_group(group_name)
  if registry[group_name] then
    for _, instance in ipairs(registry[group_name]) do
      instance:execute()
    end
  end
end

function M.abbrev(wrong, right)
  return Keymap.new('!a', wrong, right, 'Auto-correct')
end

function M.clear_abbreviations()
  -- Helper to clear all abbreviations if needed
  vim.cmd('abc') -- abbreviation clear
end

---Generates a function that executes the original keymap logic
---@param key_def table
---@return function
function M.fallback_fn(key_def)
  return function()
    if key_def.callback then
      -- It's a Lua function
      key_def.callback()
    elseif key_def.rhs then
      -- It's a string command/mapping
      local keys =
        vim.api.nvim_replace_termcodes(key_def.rhs, true, true, true)
      -- Use nvim_feedkeys to ensure <Cmd> or : commands execute in the right context
      -- 'm' uses the original mapping context, 'n' ignores remapping
      local mode = key_def.noremap and 'n' or 'm'
      vim.api.nvim_feedkeys(keys, mode, false)
    end
  end
end

---Set abbreviation that only expand when the trigger is at the position of
---a command
---@param trig string|string[]
---@param command string
---@param opts table?
function M.command_abbrev(trig, command, opts)
  -- 1. Use a more robust range expansion
  if type(trig) == 'table' then
    local short, full = trig[1], trig[2]
    -- Iterate from the length of the short version to the full version
    for i = #short, #full do
      M.command_abbrev(full:sub(1, i), command, opts)
    end
    return
  end

  -- 2. Refined expansion logic
  local expansion_fn = function()
    -- Check: 1. Are we in the cmdline (':')?
    --        2. Is the completion type a 'command'?
    --        3. Is the abbreviation at the very start of the line?
    local cmd_type = vim.fn.getcmdtype()
    local cmd_line = vim.fn.getcmdline()
    local pos = vim.fn.getcmdpos()

    -- We only expand if we are at the beginning of the command line
    -- (accounting for the length of the trigger)
    local is_start = cmd_line:sub(1, pos - 1) == trig

    if
      cmd_type == ':'
      and vim.fn.getcmdcompltype() == 'command'
      and is_start
    then
      return command
    end
    return trig
  end

  -- 3. Set the mapping
  opts = vim.tbl_deep_extend('force', {
    expr = true,
    replace_keycodes = true, -- Essential for Nightly expr maps
  }, opts or {})

  vim.keymap.set('ca', trig, expansion_fn, opts)
end

---Set keymap that only expand when the trigger is at the position of
---a command
---@param trig string
---@param command string
---@param opts table?
function M.command_map(trig, command, opts)
  local expansion_fn = function()
    local cmd_type = vim.fn.getcmdtype()
    local cmd_line = vim.fn.getcmdline()

    -- Check:
    -- 1. Are we in the command line (':')?
    -- 2. Is the command line currently empty? (Prevents mapping inside strings)
    -- 3. Is the completion type 'command'?
    if
      cmd_type == ':'
      and cmd_line == ''
      and vim.fn.getcmdcompltype() == 'command'
    then
      return command
    end
    return trig
  end

  opts = vim.tbl_deep_extend('force', {
    expr = true,
    replace_keycodes = true, -- Crucial for Nightly to interpret keys correctly
    desc = 'Smart command map: ' .. trig .. ' -> ' .. command,
  }, opts or {})

  vim.keymap.set('c', trig, expansion_fn, opts)
end

M.escape_pair = function()
  local closers = { ')', ']', '}', '>', "'", '"', '`', ',' }
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

---Close floating windows with a given key, supposed to be used in a keymap
--- 1. If current window is a floating window, close it and return
--- 2. Else, close all floating windows that can be focused
--- 3. Fallback to `key` if no floating window can be focused
---@param k string key (lhs) of the mapping
function M.close_floats(k)
  local current_win = vim.api.nvim_get_current_win()

  -- Only close current win if it's a floating window
  if vim.fn.win_gettype(current_win) == 'popup' then
    vim.api.nvim_win_close(current_win, true)
    return
  end

  -- Else close all focusable floating windows in current tab page
  local floats = vim
    .iter(vim.api.nvim_tabpage_list_wins(0))
    :filter(function(win)
      return vim.fn.win_gettype(win) == 'popup'
        and vim.api.nvim_win_get_config(win).focusable
        -- Ignore extui cmdline/message floating window, see `:h vim._extui`
        and not vim.tbl_contains(
          { 'cmd', 'dialog', 'msg', 'pager' },
          vim.bo[vim.fn.winbufnr(win)].ft
        )
    end)

  -- If no floating window will be closed, fallback
  if not floats:peek() then
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes(k, true, true, true),
      'n',
      false
    )
    return
  end

  floats:each(function(win)
    vim.api.nvim_win_close(win, false)
  end)
end

---Close floating windows with 'q'
--- 1. If current window is a floating window, close it and return
--- 2. Else, close all floating windows that can be focused
--- 3. Fallback to normal mode 'q' if no floating window can be focused
---@return nil
function M.close_float()
  local count = 0
  local current_win = vim.api.nvim_get_current_win()
  -- Close current win only if it's a floating window
  if vim.api.nvim_win_get_config(current_win).relative ~= '' then
    vim.api.nvim_win_close(current_win, true)
    return
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_is_valid(win) then
      local config = vim.api.nvim_win_get_config(win)
      -- Close floating windows that can be focused
      if config.relative ~= '' and config.focusable then
        vim.api.nvim_win_close(win, false) -- do not force
        count = count + 1
      end
    end
  end
  if count == 0 then -- Fallback
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes('q', true, true, true),
      'n',
      false
    )
  end
end

-- INFO: replaces nvim-toggle
function M.universal_smart_toggle()
  local bufnr = vim.api.nvim_get_current_buf()
  -- Use 'ignore_injections = false' to work inside embedded languages (like JS in HTML)
  local node =
    vim.treesitter.get_node({ bufnr = bufnr, ignore_injections = false })

  if not node then
    print('No node found at cursor')
    return
  end

  local node_text = vim.treesitter.get_node_text(node, bufnr)
  local node_type = node:type()
  local replacement = nil

  -- 1. Structural Toggles (Tree-sitter Booleans)
  -- Some parsers use 'boolean_literal', others just 'true' or 'false'
  if
    node_type:find('boolean')
    or node_text == 'true'
    or node_text == 'false'
    or node_text == 'True'
    or node_text == 'False'
  then
    if node_text:lower() == 'true' then
      replacement = (node_text:match('^T')) and 'False' or 'false'
    else
      replacement = (node_text:match('^F')) and 'True' or 'true'
    end

  -- 2. Number Toggles (0 <-> 1)
  elseif node_type:find('number') or node_type:find('integer') then
    if node_text == '0' then
      replacement = '1'
    elseif node_text == '1' then
      replacement = '0'
    end

  -- 3. Logical Operators & Common Pairs
  else
    local pairs = {
      ['&&'] = '||',
      ['||'] = '&&',
      ['=='] = '!=',
      ['!='] = '==',
      ['and'] = 'or',
      ['or'] = 'and',
      ['yes'] = 'no',
      ['no'] = 'yes',
      ['on'] = 'off',
      ['off'] = 'on',
      ['#f5e0dc'] = '#ffffff',
    }
    replacement = pairs[node_text]
  end

  -- Apply the change
  if replacement then
    local start_row, start_col, end_row, end_col = node:range()
    vim.api.nvim_buf_set_text(
      bufnr,
      start_row,
      start_col,
      end_row,
      end_col,
      { replacement }
    )
  else
    -- Optional: If Tree-sitter fails, try a simple word toggle under cursor
    local word = vim.fn.expand('<cword>')
    print('No toggle for: ' .. node_text .. ' (Type: ' .. node_type .. ')')
  end
end

---Amend keymap
---Caveat: currently cannot amend keymap with <Cmd>...<CR> rhs
---@param modes string[]|string
---@param lhs string
---@param rhs fun(fallback: function)
---@param opts table?
---@return nil
function M.amend(modes, lhs, rhs, opts)
  modes = type(modes) ~= 'table' and { modes } or modes
  opts = opts or {}

  for _, mode in ipairs(modes) do
    local key_def = M.get(mode, lhs)

    local rhs_fn = function()
      -- We pass the fallback logic into the user's provided 'rhs'
      rhs(M.fallback_fn(key_def))
    end

    -- Use tbl_deep_extend to merge user opts with our logic
    local final_opts = vim.tbl_deep_extend('force', opts, {
      desc = opts.desc or ('Amended: ' .. (key_def.desc or lhs)),
      buffer = opts.buffer or key_def.buffer,
    })

    vim.keymap.set(mode, lhs, rhs_fn, final_opts)
  end
end

---Cache key sequence to keycode mapping
---@type table<string, string>
local keycodes = {}

---Feed keys with repeat
---@param keys? string keys to be typed
---@param modes string behavior flags, see `feedkeys()`
---@param escape_ks boolean if true, escape `K_SPECIAL` bytes in `keys`
function M.feed(keys, modes, escape_ks)
  if not keys then
    return
  end

  local keycode = keycodes[keys]
  if not keycode then
    keycode = vim.keycode(keys)
    keycodes[keys] = keycode
  end

  vim.api.nvim_feedkeys(
    vim.v.count > 0 and vim.v.count .. keycode or keycode,
    modes,
    escape_ks
  )
end

---Wrap a function so that it repeats the original function multiple times
---according to v:count or v:count1
---@generic T
---@param fn fun(): T?
---@param count? 0|1 count given for the last normal mode command, see `:h v:count` or `:h v:count1`, default to 1
---@return fun(): T[]
function M.count_wrap(fn, count)
  return function()
    if count == 0 and vim.v.count == 0 then
      return {}
    end
    local result = {}
    for _ = 1, vim.v.count1 do
      vim.list_extend(result, { fn() })
    end
    return unpack(result)
  end
end

---Wrap a function so that it runs with `lazyredraw=true`
---@generic T
---@param fn fun(): T?
---@return fun(): T?
function M.with_lazyredraw(fn)
  return function()
    -- Avoid setting `lazyredraw` option and trigging `OptionSet` event
    -- unnecessarily
    if vim.go.lz then
      return fn()
    end
    vim.go.lz = true
    local result = { fn() }
    vim.go.lz = false
    return unpack(result)
  end
end

---Wrap a function so that the cursor position remains after running the
---function
---@generic T
---@param fn fun(): T?
---@return fun(): T?
function M.with_cursorpos(fn)
  return function()
    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local result = { fn() }
    if
      not vim.api.nvim_win_is_valid(win)
      or vim.deep_equal(cursor, vim.api.nvim_win_get_cursor(win))
    then
      return
    end
    vim.api.nvim_set_current_win(win)
    vim.api.nvim_win_set_cursor(win, cursor)
    return unpack(result)
  end
end

---Wrap a function so that current window view is kept after running it
---@generic T
---@param cb fun(): T?
---@return fun(): T?
function M.with_winview(cb)
  return function()
    local win = vim.api.nvim_get_current_win()
    local view = vim.fn.winsaveview()
    local result = { cb() }
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_call(win, function()
        vim.fn.winrestview(view)
      end)
    end
    return unpack(result)
  end
end

M.Keymap = Keymap
return M
