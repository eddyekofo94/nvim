local M = {}
local autocmd = vim.api.nvim_create_autocmd
local groupid = vim.api.nvim_create_augroup

M.create_augroup = function(group, opts)
  opts = opts or { clear = true }
  return vim.api.nvim_create_augroup(group, opts)
end

---@param group string
---@vararg { [1]: string|string[], [2]: vim.api.keyset.create_autocmd }
---@return nil
function M.augroup_autocmd(group, ...)
  local id = groupid(group, {})
  for _, a in ipairs { ... } do
    a[2].group = id
    autocmd(unpack(a))
  end
end

---Wrapper of nvim_get_hl(), but does not create a cleared highlight group
---if it doesn't exist
---NOTE: vim.api.nvim_get_hl() has a side effect, it will create a cleared
---highlight group if it doesn't exist, see
---https://github.com/neovim/neovim/issues/24583
---This affects regions highlighted by non-existing highlight groups in a
---winbar, which should falls back to the default 'WinBar' or 'WinBarNC'
---highlight groups but instead falls back to 'Normal' highlight group
---because of this side effect
---So we need to check if the highlight group exists before calling
---vim.api.nvim_get_hl()
---@param ns_id integer
---@param opts table{ name: string?, id: integer?, link: boolean? }
---@return vim.api.keyset.highlight: highlight attributes
function M.get(ns_id, opts)
  if not opts.name then
    return vim.api.nvim_get_hl(ns_id, opts)
  end
  return vim.fn.hlexists(opts.name) == 1 and vim.api.nvim_get_hl(ns_id, opts) or {}
end

---Wrapper of nvim_buf_add_highlight(), but does not create a cleared
---highlight group if it doesn't exist
---@param buffer integer buffer handle, or 0 for current buffer
---@param ns_id integer namespace to use or -1 for ungrouped highlight
---@param hl_group string name of the highlight group to use
---@param line integer line to highlight (zero-indexed)
---@param col_start integer start of (byte-indexed) column range to highlight
---@param col_end integer end of (byte-indexed) column range to highlight, or -1 to highlight to end of line
---@return nil
function M.buf_add_hl(buffer, ns_id, hl_group, line, col_start, col_end)
  if vim.fn.hlexists(hl_group) == 0 then
    return
  end
  vim.api.nvim_buf_add_highlight(buffer, ns_id, hl_group, line, col_start, col_end)
end

---Highlight text in buffer, clear previous highlight if any exists
---@param buf integer
---@param hlgroup string
---@param range winbar_symbol_range_t?
function M.range_single(buf, hlgroup, range)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local ns = vim.api.nvim_create_namespace(hlgroup)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  if range then
    for linenr = range.start.line, range["end"].line do
      local start_col = linenr == range.start.line and range.start.character or 0
      local end_col = linenr == range["end"].line and range["end"].character or -1
      M.buf_add_hl(buf, ns, hlgroup, linenr, start_col, end_col)
    end
  end
end

---Highlight a line in buffer, clear previous highlight if any exists
---@param buf integer
---@param hlgroup string
---@param linenr integer? 1-indexed line number
function M.line_single(buf, hlgroup, linenr)
  M.range_single(buf, hlgroup, linenr and {
    start = {
      line = linenr - 1,
      character = 0,
    },
    ["end"] = {
      line = linenr - 1,
      character = -1,
    },
  })
end

---Merge highlight attributes, use values from the right most hl group
---if there are conflicts
---@vararg string highlight group names
---@return vim.api.keyset.highlight: merged highlight attributes
function M.merge(...)
  -- Eliminate nil values in vararg
  local hl_names = {}
  for _, hl_name in pairs { ... } do
    if hl_name then
      table.insert(hl_names, hl_name)
    end
  end
  local hl_attr = vim.tbl_map(function(hl_name)
    return M.get(0, {
      name = hl_name,
      link = false,
    })
  end, hl_names)
  return vim.tbl_extend("force", unpack(hl_attr))
end

---@param attr_type 'fg'|'bg'
---@param fbg? string|integer
---@param default? integer
---@return integer|string|nil
function M.normalize_fg_or_bg(attr_type, fbg, default)
  if not fbg then
    return default
  end
  local data_type = type(fbg)
  if data_type == "number" then
    return fbg
  end
  if data_type == "string" then
    if vim.fn.hlexists(fbg) == 1 then
      return vim.api.nvim_get_hl(0, {
        name = fbg,
        link = false,
      })[attr_type]
    end
    if fbg:match "^#%x%x%x%x%x%x$" then
      return fbg
    end
  end
  return default
end

---Normalize highlight attributes
---1. Replace `attr.fg` and `attr.bg` with their corresponding color codes
---   if they are set to highlight group names
---2. If `attr.link` used in combination with other attributes, will first
---   retrieve the attributes of the linked highlight group, then merge
---   with other attributes
---Side effect: change `attr` table
---@param attr vim.api.keyset.highlight highlight attributes
---@return table: normalized highlight attributes
function M.normalize(attr)
  if attr.link then
    local num_keys = #vim.tbl_keys(attr)
    if num_keys <= 1 then
      return attr
    end
    attr.fg = M.normalize_fg_or_bg("fg", attr.fg)
    attr.bg = M.normalize_fg_or_bg("bg", attr.bg)
    attr = vim.tbl_extend("force", M.get(0, { name = attr.link, link = false }) or {}, attr)
    attr.link = nil
    return attr
  end
  attr.fg = M.normalize_fg_or_bg("fg", attr.fg)
  attr.bg = M.normalize_fg_or_bg("bg", attr.bg)
  return attr
end

---Wrapper of nvim_set_hl(), normalize highlight attributes before setting
---@param ns_id integer namespace id
---@param name string
---@param attr vim.api.keyset.highlight highlight attributes
---@return nil
function M.set(ns_id, name, attr)
  return vim.api.nvim_set_hl(ns_id, name, M.normalize(attr))
end

---Set default highlight attributes, normalize highlight attributes before setting
---@param ns_id integer namespace id
---@param name string
---@param attr vim.api.keyset.highlight highlight attributes
---@return nil
function M.set_default(ns_id, name, attr)
  attr.default = true
  return vim.api.nvim_set_hl(ns_id, name, M.normalize(attr))
  -- return vim.api.nvim_set_hl(ns_id, name, attr)
end

local todec = {
  ["0"] = 0,
  ["1"] = 1,
  ["2"] = 2,
  ["3"] = 3,
  ["4"] = 4,
  ["5"] = 5,
  ["6"] = 6,
  ["7"] = 7,
  ["8"] = 8,
  ["9"] = 9,
  ["a"] = 10,
  ["b"] = 11,
  ["c"] = 12,
  ["d"] = 13,
  ["e"] = 14,
  ["f"] = 15,
  ["A"] = 10,
  ["B"] = 11,
  ["C"] = 12,
  ["D"] = 13,
  ["E"] = 14,
  ["F"] = 15,
}

---Convert an integer from hexadecimal to decimal
---@param hex string
---@return integer dec
function M.hex2dec(hex)
  local digit = 1
  local dec = 0
  while digit <= #hex do
    dec = dec + todec[string.sub(hex, digit, digit)] * 16 ^ (#hex - digit)
    digit = digit + 1
  end
  return dec
end

---Convert an integer from decimal to hexadecimal
---@param int integer
---@param n_digits integer? number of digits used for the hex code
---@return string hex
function M.dec2hex(int, n_digits)
  return not n_digits and string.format("%x", int) or string.format("%0" .. n_digits .. "x", int)
end

---Convert a hex color to rgb color
---@param hex string hex code of the color
---@return integer[] rgb
function M.hex2rgb(hex)
  return {
    M.hex2dec(string.sub(hex, 1, 2)),
    M.hex2dec(string.sub(hex, 3, 4)),
    M.hex2dec(string.sub(hex, 5, 6)),
  }
end

---Convert an rgb color to hex color
---@param rgb integer[]
---@return string
function M.rgb2hex(rgb)
  local hex = {
    M.dec2hex(math.floor(rgb[1])),
    M.dec2hex(math.floor(rgb[2])),
    M.dec2hex(math.floor(rgb[3])),
  }
  hex = {
    string.rep("0", 2 - #hex[1]) .. hex[1],
    string.rep("0", 2 - #hex[2]) .. hex[2],
    string.rep("0", 2 - #hex[3]) .. hex[3],
  }
  return table.concat(hex, "")
end

---Blend two colors
---@param c1 string|number|table the first color, in hex, dec, or rgb
---@param c2 string|number|table the second color, in hex, dec, or rgb
---@param alpha number? between 0~1, weight of the first color, default to 0.5
---@return { hex: string, dec: integer, r: integer, g: integer, b: integer }
function M.cblend(c1, c2, alpha)
  alpha = alpha or 0.5
  c1 = type(c1) == "number" and M.dec2hex(c1, 6) or c1
  c2 = type(c2) == "number" and M.dec2hex(c2, 6) or c2
  local rgb1 = type(c1) == "string" and M.hex2rgb(c1:gsub("#", "", 1)) or c1
  local rgb2 = type(c2) == "string" and M.hex2rgb(c2:gsub("#", "", 1)) or c2
  local rgb_blended = {
    alpha * rgb1[1] + (1 - alpha) * rgb2[1],
    alpha * rgb1[2] + (1 - alpha) * rgb2[2],
    alpha * rgb1[3] + (1 - alpha) * rgb2[3],
  }
  local hex = M.rgb2hex(rgb_blended)
  return {
    hex = "#" .. hex,
    dec = M.hex2dec(hex),
    r = math.floor(rgb_blended[1]),
    g = math.floor(rgb_blended[2]),
    b = math.floor(rgb_blended[3]),
  }
end

---Blend two hlgroups
---@param h1 string|table the first hlgroup name or highlight attribute table
---@param h2 string|table the second hlgroup name or highlight attribute table
---@param alpha number? between 0~1, weight of the first color, default to 0.5
---@return table: merged color or highlight attributes
function M.blend(h1, h2, alpha)
  -- stylua: ignore start
  h1 = type(h1) == 'table' and h1 or M.get(0, { name = h1, link = false })
  h2 = type(h2) == 'table' and h1 or M.get(0, { name = h2, link = false })
  local fg = h1.fg and h2.fg and M.cblend(h1.fg, h2.fg, alpha).dec or h1.fg or h2.fg
  local bg = h1.bg and h2.bg and M.cblend(h1.bg, h2.bg, alpha).dec or h1.bg or h2.bg
  return vim.tbl_deep_extend('force', h1, h2, { fg = fg, bg = bg })
  -- stylua: ignore end
end

---Get string representation of a string with highlight
---@param str? string sign symbol
---@param hl? string name of the highlight group
---@param restore? boolean restore highlight after the sign, default true
---@return string sign string representation of the sign with highlight
function M.hl(str, hl, restore)
  restore = restore == nil or restore
  if restore then
    return table.concat { "%#", hl or "", "#", str or "", "%*" }
  else
    return table.concat { "%#", hl or "", "#", str or "" }
  end
end

function M.sethl_default(hlgroup_name, attr)
  -- local merged_attr = vim.tbl_deep_extend("keep", attr, default_attr)
  M.set_default(0, hlgroup_name, attr)
end

function M.sethl(hlgroup_name, attr)
  -- local merged_attr = vim.tbl_deep_extend("keep", attr, default_attr)
  M.set(0, hlgroup_name, attr)
end

-- Set highlight groups
--@param hlgroups table of hlgroups
function M.sethl_groups(hlgroups)
  -- Set highlight groups
  for hlgroup_name, hlgroup_attr in pairs(hlgroups) do
    -- vim.api.nvim_set_hl(0, hlgroup_name, hlgroup_attr)
    M.sethl(hlgroup_name, hlgroup_attr)
  end
end

function M.gethl(hlgroup_name, attr)
  return M.get(0, { name = hlgroup_name })[attr]
end

--- regex used for matching a valid URL/URI string
M.url_matcher =
  "\\v\\c%(%(h?ttps?|ftp|file|ssh|git)://|[a-z]+[@][a-z]+[.][a-z]+:)%([&:#*@~%_\\-=?!+;/0-9a-z]+%(%([.;/?]|[.][.]+)[&:#*@~%_\\-=?!+/0-9a-z]+|:\\d+|,%(%(%(h?ttps?|ftp|file|ssh|git)://|[a-z]+[@][a-z]+[.][a-z]+:)@![0-9a-z]+))*|\\([&:#*@~%_\\-=?!+;/.0-9a-z]*\\)|\\[[&:#*@~%_\\-=?!+;/.0-9a-z]*\\]|\\{%([&:#*@~%_\\-=?!+;/.0-9a-z]*|\\{[&:#*@~%_\\-=?!+;/.0-9a-z]*})\\})+"

--- Delete the syntax matching rules for URLs/URIs if set
function M.delete_url_match()
  for _, match in ipairs(vim.fn.getmatches()) do
    if match.group == "HighlightURL" then
      vim.fn.matchdelete(match.id)
    end
  end
end

--- Add syntax matching rules for highlighting URLs/URIs
function M.set_url_match()
  M.delete_url_match()
  if vim.g.highlighturl_enabled then
    vim.fn.matchadd("HighlightURL", M.url_matcher, 15)
  end
end

function M.starts_with(str, start)
  return str:sub(1, #start) == start
end

function M.is_table(to_check)
  return type(to_check) == "table"
end

function M.has_key(t, key)
  for t_key, _ in pairs(t) do
    if t_key == key then
      return true
    end
  end
  return false
end

function M.has_value(t, val)
  for _, value in ipairs(t) do
    if value == val then
      return true
    end
  end
  return false
end

function M.tprint(table)
  print(vim.inspect(table))
end

function M.tprint_keys(table)
  for k in pairs(table) do
    print(k)
  end
end
---runs :normal with bang
---@param cmdStr string
function M.normal(cmdStr)
  vim.cmd.normal { cmdStr, bang = true }
end

local function escape(str)
  return str:gsub("%%", "%%%%")
end

--- Merge extended options with a default table of options
---@param default? table The default table that you want to merge into
---@param opts? table The new options that should be merged with the default table
---@return table # The merged table
function M.extend_tbl(default, opts)
  opts = opts or {}
  return default and vim.tbl_deep_extend("force", default, opts) or opts
end

--- Partially reload AstroNvim user settings. Includes core vim options, mappings, and highlights. This is an experimental feature and may lead to instabilities until restart.
---@param quiet? boolean Whether or not to notify on completion of reloading
---@return boolean # True if the reload was successful, False otherwise
function M.reload(quiet)
  local was_modifiable = vim.opt.modifiable:get()
  if not was_modifiable then
    vim.opt.modifiable = true
  end
  local core_modules = { "plugins", "autocommands", "keymaps" }
  local modules = vim.tbl_filter(function(module)
    return module:find "^user%."
  end, vim.tbl_keys(package.loaded))

  vim.tbl_map(require("plenary.reload").reload_module, vim.list_extend(modules, core_modules))

  local success = true
  for _, module in ipairs(core_modules) do
    local status_ok, fault = pcall(require, module)
    if not status_ok then
      vim.api.nvim_err_writeln("Failed to load " .. module .. "\n\n" .. fault)
      success = false
    end
  end
  if not was_modifiable then
    vim.opt.modifiable = false
  end
  if not quiet then -- if not quiet, then notify of result
    if success then
      M.notify("Config successfully reloaded", "info")
    else
      M.notify("Error reloading Config...", "error")
    end
  end
  vim.cmd.doautocmd "ColorScheme"
  return success
end

--- Insert one or more values into a list like table and maintain that you do not insert non-unique values (THIS MODIFIES `lst`)
---@param lst any[]|nil The list like table that you want to insert into
---@param vals any|any[] Either a list like table of values to be inserted or a single value to be inserted
---@return any[] # The modified list like table
function M.list_insert_unique(lst, vals)
  if not lst then
    lst = {}
  end
  assert(vim.tbl_islist(lst), "Provided table is not a list like table")
  if not vim.tbl_islist(vals) then
    vals = { vals }
  end
  local added = {}
  vim.tbl_map(function(v)
    added[v] = true
  end, lst)
  for _, val in ipairs(vals) do
    if not added[val] then
      table.insert(lst, val)
      added[val] = true
    end
  end
  return lst
end

--- Call function if a condition is met
---@param func function The function to run
---@param condition boolean # Whether to run the function or not
---@return any|nil result # the result of the function running or nil
function M.conditional_func(func, condition, ...)
  -- if the condition is true or no condition is provided, evaluate the function with the rest of the parameters and return the result
  if condition and type(func) == "function" then
    return func(...)
  end
end

--- A utility function to stylize a string with an icon from lspkind, separators, and left/right padding
---@param str? string the string to stylize
---@param opts? table options of `{ padding = { left = 0, right = 0 }, separator = { left = "|", right = "|" }, escape = true, show_empty = false, icon = { kind = "NONE", padding = { left = 0, right = 0 } } }`
---@return string # the stylized string
-- @usage local string = require("astronvim.utils.status").utils.stylize("Hello", { padding = { left = 1, right = 1 }, icon = { kind = "String" } })
function M.stylize(str, opts)
  opts = M.extend_tbl({
    padding = { left = 0, right = 0 },
    separator = { left = "", right = "" },
    show_empty = false,
    escape = true,
    icon = { kind = "NONE", padding = { left = 0, right = 0 } },
  }, opts)
  local icon = M.pad_string(M.get_icon(opts.icon.kind), opts.icon.padding)
  return str
      and (str ~= "" or opts.show_empty)
      and opts.separator.left .. M.pad_string(icon .. (opts.escape and escape(str) or str), opts.padding) .. opts.separator.right
    or ""
end

--- Get an icon from the AstroNvim internal icons if it is available and return it
---@param kind string The kind of icon in astronvim.icons to retrieve
---@param padding? integer Padding to add to the end of the icon
---@param no_fallback? boolean Whether or not to disable fallback to text icon
---@return string icon
function M.get_icon(kind, padding, no_fallback)
  if not vim.g.icons_enabled and no_fallback then
    return ""
  end
  local icon_pack = vim.g.icons_enabled and "icons" or "text_icons"
  if not M[icon_pack] then
    M.icons = require "utils.static.icons"
    M.text_icons = require "utils.static.icons._icons_retro"
  end
  local icon = M[icon_pack] and M[icon_pack][kind]
  return icon and icon .. string.rep(" ", padding or 0) or ""
end

--- Get a icon spinner table if it is available in the AstroNvim icons. Icons in format `kind1`,`kind2`, `kind3`, ...
---@param kind string The kind of icon to check for sequential entries of
---@return string[]|nil spinners # A collected table of spinning icons in sequential order or nil if none exist
function M.get_spinner(kind, ...)
  local spinner = {}
  repeat
    local icon = M.get_icon(("%s%d"):format(kind, #spinner + 1), ...)
    if icon ~= "" then
      table.insert(spinner, icon)
    end
  until not icon or icon == ""
  if #spinner > 0 then
    return spinner
  end
end

--- Get highlight properties for a given highlight name
---@param name string The highlight group name
---@param fallback? table The fallback highlight properties
---@return table properties # the highlight group properties
function M.get_hlgroup(name, fallback)
  if vim.fn.hlexists(name) == 1 then
    local hl
    if vim.api.nvim_get_hl then -- check for new neovim 0.9 API
      hl = vim.api.nvim_get_hl(0, { name = name, link = false })
      if not hl.fg then
        hl.fg = "NONE"
      end
      if not hl.bg then
        hl.bg = "NONE"
      end
    else
      hl = vim.api.nvim_get_hl_by_name(name, vim.o.termguicolors)
      if not hl.foreground then
        hl.foreground = "NONE"
      end
      if not hl.background then
        hl.background = "NONE"
      end
      hl.fg, hl.bg = hl.foreground, hl.background
      hl.ctermfg, hl.ctermbg = hl.fg, hl.bg
      hl.sp = hl.special
    end
    return hl
  end
  return fallback or {}
end

--- Serve a notification with a custom title
---@param msg string The notification body
---@param level? string The type of the notification (:help vim.log.levels)
---@param opts? table The nvim-notify options to use (:help notify-options)
function M.notify(msg, level, opts)
  vim.schedule(function()
    if not level then
      level = "info"
    end
    vim.notify(msg, vim.log.levels[level:upper()], M.extend_tbl({ title = "Custom" }, opts))
  end)
end

--- Serve a notification once with a custom title
---@param msg string The notification body
---@param level? string The type of the notification (:help vim.log.levels)
---@param opts? table The nvim-notify options to use (:help notify-options)
function M.notify_once(msg, level, opts)
  vim.schedule(function()
    if not level then
      level = "info"
    end
    vim.notify_once(msg, vim.log.levels[level:upper()], M.extend_tbl({ title = "Custom" }, opts))
  end)
end

--- Trigger an AstroNvim user event
---@param event string The event name to be appended to Custom
---@param delay? boolean Whether or not to delay the event asynchronously (Default: true)
function M.event(event, delay)
  local emit_event = function()
    vim.api.nvim_exec_autocmds("User", { pattern = "Custom" .. event, modeline = false })
  end
  if delay == false then
    emit_event()
  else
    vim.schedule(emit_event)
  end
end

--- Open a URL under the cursor with the current operating system
---@param path string The path of the file to open with the system opener
function M.system_open(path)
  -- TODO: REMOVE WHEN DROPPING NEOVIM <0.10
  if vim.ui.open then
    return vim.ui.open(path)
  end
  local cmd
  if vim.fn.has "win32" == 1 and vim.fn.executable "explorer" == 1 then
    cmd = { "cmd.exe", "/K", "explorer" }
  elseif vim.fn.has "unix" == 1 and vim.fn.executable "xdg-open" == 1 then
    cmd = { "xdg-open" }
  elseif (vim.fn.has "mac" == 1 or vim.fn.has "unix" == 1) and vim.fn.executable "open" == 1 then
    cmd = { "open" }
  end
  if not cmd then
    M.notify("Available system opening tool not found!", "error")
  end
  vim.fn.jobstart(vim.fn.extend(cmd, { path or vim.fn.expand "<cfile>" }), { detach = true })
end

--- Create a button entity to use with the alpha dashboard
---@param sc string The keybinding string to convert to a button
---@param txt string The explanation text of what the keybinding does
---@return table # A button entity table for an alpha configuration
function M.alpha_button(sc, txt)
  -- replace <leader> in shortcut text with LDR for nicer printing
  local sc_ = sc:gsub("%s", ""):gsub("LDR", "<Leader>")
  -- if the leader is set, replace the text with the actual leader key for nicer printing
  if vim.g.mapleader then
    sc = sc:gsub("LDR", vim.g.mapleader == " " and "SPC" or vim.g.mapleader)
  end
  -- return the button entity to display the correct text and send the correct keybinding on press
  return {
    type = "button",
    val = txt,
    on_press = function()
      local key = vim.api.nvim_replace_termcodes(sc_, true, false, true)
      vim.api.nvim_feedkeys(key, "normal", false)
    end,
    opts = {
      position = "center",
      text = txt,
      shortcut = sc,
      cursor = -2,
      width = 36,
      align_shortcut = "right",
      hl = "DashboardCenter",
      hl_shortcut = "DashboardShortcut",
    },
  }
end

--- Check if a plugin is defined in lazy. Useful with lazy loading when a plugin is not necessarily loaded yet
---@param plugin string The plugin to search for
---@return boolean available # Whether the plugin is available
function M.is_available(plugin)
  local lazy_config_avail, lazy_config = pcall(require, "lazy.core.config")
  return lazy_config_avail and lazy_config.spec.plugins[plugin] ~= nil
end

--- Resolve the options table for a given plugin with lazy
---@param plugin string The plugin to search for
---@return table opts # The plugin options
function M.plugin_opts(plugin)
  local lazy_config_avail, lazy_config = pcall(require, "lazy.core.config")
  local lazy_plugin_avail, lazy_plugin = pcall(require, "lazy.core.plugin")
  local opts = {}
  if lazy_config_avail and lazy_plugin_avail then
    local spec = lazy_config.spec.plugins[plugin]
    if spec then
      opts = lazy_plugin.values(spec, "opts")
    end
  end
  return opts
end

--- A helper function to wrap a module function to require a plugin before running
---@param plugin string The plugin to call `require("lazy").load` with
---@param module table The system module where the functions live (e.g. `vim.ui`)
---@param func_names string|string[] The functions to wrap in the given module (e.g. `{ "ui", "select }`)
function M.load_plugin_with_func(plugin, module, func_names)
  if type(func_names) == "string" then
    func_names = { func_names }
  end
  for _, func in ipairs(func_names) do
    local old_func = module[func]
    module[func] = function(...)
      module[func] = old_func
      require("lazy").load { plugins = { plugin } }
      module[func](...)
    end
  end
end

--- regex used for matching a valid URL/URI string
M.url_matcher =
  "\\v\\c%(%(h?ttps?|ftp|file|ssh|git)://|[a-z]+[@][a-z]+[.][a-z]+:)%([&:#*@~%_\\-=?!+;/0-9a-z]+%(%([.;/?]|[.][.]+)[&:#*@~%_\\-=?!+/0-9a-z]+|:\\d+|,%(%(%(h?ttps?|ftp|file|ssh|git)://|[a-z]+[@][a-z]+[.][a-z]+:)@![0-9a-z]+))*|\\([&:#*@~%_\\-=?!+;/.0-9a-z]*\\)|\\[[&:#*@~%_\\-=?!+;/.0-9a-z]*\\]|\\{%([&:#*@~%_\\-=?!+;/.0-9a-z]*|\\{[&:#*@~%_\\-=?!+;/.0-9a-z]*})\\})+"

--- Run a shell command and capture the output and if the command succeeded or failed
---@param cmd string|string[] The terminal command to execute
---@param show_error? boolean Whether or not to show an unsuccessful command as an error to the user
---@return string|nil # The result of a successfully executed command or nil
function M.cmd(cmd, show_error)
  if type(cmd) == "string" then
    cmd = { cmd }
  end
  if vim.fn.has "win32" == 1 then
    cmd = vim.list_extend({ "cmd.exe", "/C" }, cmd)
  end
  local result = vim.fn.system(cmd)
  local success = vim.api.nvim_get_vvar "shell_error" == 0
  if not success and (show_error == nil or show_error) then
    vim.api.nvim_err_writeln(("Error running command %s\nError message:\n%s"):format(table.concat(cmd, " "), result))
  end
  return success and result:gsub("[\27\155][][()#;?%d]*[A-PRZcf-ntqry=><~]", "") or nil
end

function M.define_augroups(definitions) -- {{{1
  -- Create autocommand groups based on the passed definitions
  --
  -- The key will be the name of the group, and each definition
  -- within the group should have:
  --    1. Trigger
  --    2. Pattern
  --    3. Text
  -- just like how they would normally be defined from Vim itself
  for group_name, definition in pairs(definitions) do
    vim.cmd("augroup " .. group_name)
    vim.cmd "autocmd!"

    for _, def in pairs(definition) do
      local command = table.concat(vim.tbl_flatten { "autocmd", def }, " ")
      vim.cmd(command)
    end

    vim.cmd "augroup END"
  end
end
return M
