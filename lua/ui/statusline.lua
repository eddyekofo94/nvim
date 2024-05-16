_G.statusline = {}

local fs = require "utils.fs"
local Buffer = require "utils.buffer"
local utils = require "utils"
local contains = vim.tbl_contains

local ts_buffer = {
  "prompt",
  "qf",
  "checkhealth",
  "nofile",
  "quickfix",
  "git-conflict",
  "term",
  "lazygit",
  "oil",
  "dap-repl",
  "dapui_scopes",
  "dapui_stacks",
  "dapui_breakpoints",
  "dapui_console",
  "dapui_watches",
  "dapui_repl",
  "undotree",
  "noice",
  "man",
  "messages",
  "undotree",
  "help",
  "NeogitStatus",
  "notify",
  "Trouble",
  "diffview",
  "telescope",
  "lazy",
  "Outline",
  "TelescopePrompt",
  "TelescopeResults",
  "TelescopePreview",
}
local options = {
  diagnostics = {
    " 0 ",
    "󰅚 0 ",
  },
  default_icon = "󰈚 ",
  hl = {},
  symbols = {
    modified = "● ",
    readonly = "🔒 ",
    unnamed = "[No Name]",
    newfile = "[New]",
  },
  file_status = true,
  newfile_status = false,
  path = 0,
  shorting_target = 40,
}
local function is_activewin()
  return vim.api.nvim_get_current_win() == vim.g.statusline_winid
end

local stbufnr = function()
  return vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
end

local assets = {
  dir = "󰉖 ",
  file = "󰈙 ",
}

-- local get_file_icon = function()
--   local filename = vim.fn.expand "%:t"
--   local extension = vim.fn.expand "%:e"
--   local present, icons = pcall(require, "nvim-web-devicons")
--   local icon = present and icons.get_icon(filename, extension) or assets.file
--   return " " .. icon .. " "
-- end

function statusline.lsp_progress()
  local progress = require("plugins.lsp.lsp-progress").message()
  -- local progress = require("utils.lsp.progress").lsp_progress()

  return string.format(
    "%s",
    progress

    -- require("lsp-progress").progress {
    --   max_size = 80,
    --   format = function(messages)
    --     if #messages > 0 then
    --       return #messages > 0 and table.concat(messages, " ") or ""
    --     end
    --     return ""
    --   end,
    -- }
  )
end

function statusline.LSP_Diagnostics()
  local errors = #vim.diagnostic.get(stbufnr(), { severity = vim.diagnostic.severity.ERROR })
  local warnings = #vim.diagnostic.get(stbufnr(), { severity = vim.diagnostic.severity.WARN })
  local hints = #vim.diagnostic.get(stbufnr(), { severity = vim.diagnostic.severity.HINT })
  local info = #vim.diagnostic.get(stbufnr(), { severity = vim.diagnostic.severity.INFO })

  errors = (errors and errors > 0) and ("󰅚 " .. errors .. " ") or ""
  warnings = (warnings and warnings > 0) and (" " .. warnings .. " ") or ""
  hints = (hints and hints > 0) and ("󰛩 " .. hints .. " ") or ""
  info = (info and info > 0) and (" " .. info .. " ") or ""

  local icons = string.format("%s%s%s%s", errors, warnings, hints, info)
  local diagnostic_icon = (vim.o.columns > 140 and icons or "")

  return diagnostic_icon
end

statusline.lsp_msg = function()
  if not rawget(vim, "lsp") or vim.lsp.status or not is_activewin() then
    return ""
  end

  local Lsp = vim.lsp.status()

  if vim.o.columns < 120 or not Lsp then
    return ""
  end

  if Lsp.done then
    vim.defer_fn(function()
      vim.cmd.redrawstatus()
    end, 1000)
  end

  local msg = Lsp.message or ""
  local percentage = Lsp.percentage or 0
  local title = Lsp.title or ""
  local spinners = { "", "󰪞", "󰪟", "󰪠", "󰪢", "󰪣", "󰪤", "󰪥" }
  local ms = vim.loop.hrtime() / 1000000
  local frame = math.floor(ms / 120) % #spinners
  local content = string.format(" %%<%s %s %s (%s%%%%) ", spinners[frame + 1], title, msg, percentage)

  return content or ""
end

function statusline.search_count()
  if vim.v.hlsearch == 0 then
    return ""
  end

  local result = vim.fn.searchcount { maxcount = 999, timeout = 250 }

  if result.incomplete == 1 or next(result) == nil then
    return ""
  end

  return string.format("[%d/%d]", result.current, math.min(result.total, result.maxcount))
end

function statusline.file_info()
  local symbols = {}
  local fname_hl = "MiniStatuslineFileinfo"
  local fpath = statusline.filepath()
  local filename = statusline.filename()
  local devicons_present, devicons = pcall(require, "nvim-web-devicons")
  local icon = ""

  local errors = #vim.diagnostic.get(stbufnr(), { severity = vim.diagnostic.severity.ERROR })

  if devicons_present then
    local ft_icon = devicons.get_icon(filename)
    icon = (ft_icon ~= nil and ft_icon) or icon
  end

  if filename ~= options.symbols.unnamed then
    if options.file_status then
      if vim.bo.modified then
        table.insert(symbols, options.symbols.modified)
        fname_hl = "MiniStatuslineModified"
      end
      if vim.bo.modifiable == false or vim.bo.readonly == true then
        table.insert(symbols, options.symbols.readonly)
      end
    end
  else
    fpath = ""
    filename = statusline.ft()
  end

  if options.newfile_status and fs.is_new_file() then
    table.insert(symbols, options.symbols.newfile)
  end

  if errors > 0 then
    fname_hl = "MiniStatuslineError"
  end

  local file_symbol = (#symbols > 0 and " " .. table.concat(symbols, "") or "")
  return string.format("%s%s%s", "%#MiniStatuslineInactive#" .. icon .. fpath, "%#" .. fname_hl .. "#" .. filename, file_symbol)
end

function statusline.macro()
  local recording_register = vim.fn.reg_recording()
  if recording_register == "" then
    return ""
  else
    return "Recording @" .. recording_register .. " "
  end
end

statusline.project_name = function()
  local fnamemodify = vim.fn.fnamemodify
  local current_project_folder = fnamemodify(vim.fn.getcwd(), ":t")
  local parent_project_folder = fnamemodify(vim.fn.getcwd(), ":h:t")
  -- return parent_project_folder .. "/" .. current_project_folder
  return current_project_folder
end

function statusline.filename()
  local fname = vim.fn.expand "%:t"
  if fname == "" then
    return "[No Name]"
  end
  return fname
end

function statusline.filepath()
  local fpath = vim.fn.fnamemodify(vim.fn.expand "%", ":~:.:h")
  if fpath == "" or fpath == "." then
    return " "
  end

  return string.format(" %%<%s/", fpath)
end

function statusline.cwd()
  local icon = " 󰉋  "
  local name = fs.shorten_path(fs.get_root(), "/", 0)
  name = (name:match "([^/\\]+)[/\\]*$" or name) .. " "

  return (vim.o.columns > 85 and ("%#st_mode#" .. icon .. name)) or ""
end

function statusline.lsp()
  if rawget(vim, "lsp") then
    -- local client = vim.lsp.get_client_by_id(ctx.client_id)
    for _, client in ipairs(vim.lsp.get_clients()) do
      if client.attached_buffers[stbufnr()] and client.name ~= "null-ls" then
        return (vim.o.columns > 100 and "   " .. client.name .. " ") or ""
      end
    end
  end

  return ""
end

---Get diff stats for current buffer
---@return string
function statusline.gitdiff()
  -- Integration with gitsigns.nvim
  ---@diagnostic disable-next-line: undefined-field
  local diff = vim.b.gitsigns_status_dict or utils.git.diffstat()
  local added = diff.added or 0
  local changed = diff.changed or 0
  local removed = diff.removed or 0
  if added == 0 and removed == 0 and changed == 0 then
    return ""
  end
  return string.format(
    "[ +%s ~%s -%s ]",
    utils.stl.hl(tostring(added), "StatusLineGitAdded"),
    utils.stl.hl(tostring(changed), "StatusLineGitChanged"),
    utils.stl.hl(tostring(removed), "StatusLineGitRemoved")
  )
end

function statusline.vcs()
  local git_info = vim.b.gitsigns_status_dict
  if not git_info or git_info.head == "" then
    return ""
  end
  local added = git_info.added and ("%#MiniStatuslineGitAdd#+" .. git_info.added .. " ") or ""
  local changed = git_info.changed and ("%#MiniStatuslineGitChange#~" .. git_info.changed .. " ") or ""
  local removed = git_info.removed and ("%#MiniStatuslineGitDelete#-" .. git_info.removed .. " ") or ""
  if git_info.added == 0 then
    added = ""
  end
  if git_info.changed == 0 then
    changed = ""
  end
  if git_info.removed == 0 then
    removed = ""
  end
  return table.concat {
    "%#StatusLine# ",
    git_info.head,
    " ",
    added,
    changed,
    removed,
    " %#StatusLine#",
  }
end

---Get string representation of current git branch
---@return string
function statusline.branch()
  ---@diagnostic disable-next-line: undefined-field
  local branch = vim.b.gitsigns_status_dict and vim.b.gitsigns_status_dict.head or utils.git.branch()
  return branch == "" and "" or " " .. branch
end

--- A provider function for showing if treesitter is connected
---@return string # function for outputting TS if treesitter is connected
-- @see astronvim.utils.status.utils.stylize
function statusline.treesitter_status()
  local utils_buffer = require "utils.buffer"
  local current = vim.api.nvim_get_current_win()

  local ts_enabled = vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()]
  return utils_buffer.is_win_valid(current) and ts_enabled and "TS" or ""
end

---Get current filetype
---@return string
function statusline.ft()
  return vim.bo.ft == "" and "" or " " .. vim.bo.ft:gsub("^%l", string.upper) .. " "
end

function statusline.line_percentage()
  local curr_line = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_line_count(0)

  if curr_line == 1 then
    return "Top "
  elseif curr_line == lines then
    return "Bot "
  else
    return string.format("%2d%%%% ", math.ceil(curr_line / lines * 99))
  end
end

statusline.section_location = function()
  return "%2l:%-2v"
end

function statusline.lineinfo()
  if vim.bo.filetype == "alpha" then
    return ""
  end
  return " %l:%c %P "
end

---@return string
function statusline.wordcount()
  local words, wordcount = 0, nil
  if vim.b.wc_words and vim.b.wc_changedtick == vim.b.changedtick then
    words = vim.b.wc_words
  else
    wordcount = vim.fn.wordcount()
    words = wordcount.words
    vim.b.wc_words = words
    vim.b.wc_changedtick = vim.b.changedtick
  end
  local vwords = vim.fn.mode():find "^[vsVS\x16\x13]" and (wordcount or vim.fn.wordcount()).visual_words
  return words == 0 and "" or (vwords and vwords > 0 and vwords .. "/" or "") .. words .. (words > 1 and " words" or " word")
end

---Text filetypes
---@type table<string, true>
local ft_text = {
  [""] = true,
  ["tex"] = true,
  ["markdown"] = true,
  ["text"] = true,
}

---Additional info for the current buffer enclosed in parentheses
---@return string
function statusline.info()
  if vim.bo.bt ~= "" then
    return ""
  end
  local info = {}
  ---@param section string
  local function add_section(section)
    if section ~= "" then
      table.insert(info, section)
    end
  end
  add_section(statusline.ft())
  if ft_text[vim.bo.ft] and not vim.b.bigfile then
    add_section(statusline.wordcount())
  end
  -- add_section(statusline.branch())
  -- add_section(statusline.gitdiff())
  -- add_section(statusline.vcs())
  -- add_section(statusline.wordcount())
  add_section(statusline.lsp())
  add_section(statusline.treesitter_status())
  return vim.tbl_isempty(info) and "" or string.format("(%s) ", table.concat(info, ", "))
end

statusline.navic = function()
  if not pcall(require, "nvim-navic") then
    return ""
  end
  local nvim_navic = require "nvim-navic"
  if not nvim_navic.is_available() then
    return ""
  end
  return nvim_navic.get_location()
end

return statusline
