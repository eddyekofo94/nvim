local utils = require "utils"
local icons = require "utils.static.icons"
local groupid = vim.api.nvim_create_augroup("statusline", {})

_G._statusline = {}

local diag_signs_default_text = { "E", "W", "I", "H" }
local diag_severity_map = {
  [1] = "ERROR",
  [2] = "WARN",
  [3] = "INFO",
  [4] = "HINT",
  ERROR = 1,
  WARN = 2,
  INFO = 3,
  HINT = 4,
}

---@return string
local function get_diagnostic_hl()
  local has_errors = #vim.diagnostic.get(
    0,
    { severity = vim.diagnostic.severity.ERROR }
  ) > 0
  local is_modified = vim.bo.modified

  if has_errors then
    return "StatusLineFileError"
  elseif is_modified then
    return "StatusLineFileModified"
  else
    return "StatusLine"
  end
end

-- Maximum widths
local gitbranch_max_width = 0.3 -- maximum width of git branch name
local wordcount_max_width = 0.2 -- maximum width of word count info
local fname_max_width = 0.4 -- maximum width of buf/filename (without extension)
local fname_special_max_width = 0.8 -- maximum width of special buf/filename
local fname_ext_max_width = 0.2 -- maximum width of filename extension
local fname_prefix_suffix_max_width = 0.2 -- maximum width of filename prefix/suffix (extra info)

---Shorten string to a percentage of statusline width
---@param str string
---@param percent number
---@param str_alt? string alternate string to use when `str` exceeds max width
---@return string
local function str_shorten(str, percent, str_alt)
  str = tostring(str)

  local stl_width = vim.go.laststatus == 3 and vim.go.columns
    or vim.api.nvim_win_get_width(0)
  local max_width = math.ceil(stl_width * percent)
  local str_width = vim.fn.strdisplaywidth(str)
  if str_width <= max_width then
    return str
  end

  if str_alt then
    return str_alt
  end

  local ellipsis = vim.trim(icons.Ellipsis)
  local ellipsis_width = vim.fn.strdisplaywidth(ellipsis)
  local max_substr_width = max_width - ellipsis_width

  -- Ellipsis itself is wider than allowed substring width
  if max_substr_width <= 0 then
    return str:sub(1, 1)
  end

  -- Since a character can have length >= 1, we can only truncate more not less
  -- than desired
  local width_diff = str_width - max_substr_width
  local substr_nchars = math.max(1, vim.fn.strcharlen(str) - width_diff)

  return vim.fn.strcharpart(str, 0, substr_nchars) .. ellipsis
end

---@param severity integer|string
---@return string
local function get_diag_sign_text(severity)
  local diag_config = vim.diagnostic.config()
  local signs_text = diag_config
    and diag_config.signs
    and type(diag_config.signs) == "table"
    and diag_config.signs.text
  return signs_text
      and (signs_text[severity] or signs_text[diag_severity_map[severity]])
    or (
      diag_signs_default_text[severity]
      or diag_signs_default_text[diag_severity_map[severity]]
    )
end

-- stylua: ignore start
local modes = {
  ['n']      = 'NO',
  ['no']     = 'OP',
  ['nov']    = 'OC',
  ['noV']    = 'OL',
  ['no\x16'] = 'OB',
  ['\x16']   = 'VB',
  ['niI']    = 'IN',
  ['niR']    = 'RE',
  ['niV']    = 'RV',
  ['nt']     = 'NT',
  ['ntT']    = 'TM',
  ['v']      = 'VI',
  ['vs']     = 'VI',
  ['V']      = 'VL',
  ['Vs']     = 'VL',
  ['\x16s']  = 'VB',
  ['s']      = 'SE',
  ['S']      = 'SL',
  ['\x13']   = 'SB',
  ['i']      = 'IN',
  ['ic']     = 'IC',
  ['ix']     = 'IX',
  ['R']      = 'RE',
  ['Rc']     = 'RC',
  ['Rx']     = 'RX',
  ['Rv']     = 'RV',
  ['Rvc']    = 'RC',
  ['Rvx']    = 'RX',
  ['c']      = 'CO',
  ['cv']     = 'CV',
  ['r']      = 'PR',
  ['rm']     = 'PM',
  ['r?']     = 'P?',
  ['!']      = 'SH',
  ['t']      = 'TE',
}
-- stylua: ignore end

---Get string representation of the current mode
---@return string
function _G._statusline.mode()
  local hl = vim.bo.mod and "StatusLineHeaderModified" or "StatusLineHeader"
  local mode = vim.fn.mode()
  local mode_str = (mode == "n" and (vim.bo.ro or not vim.bo.ma)) and "RO"
    or modes[mode]
  return utils.stl.hl(string.format(" %s ", mode_str), hl) .. " "
end

---Get diff stats for current buffer
---@return string
function _G._statusline.gitdiff()
  local ok, work_tree, git_dir = pcall(
    utils.git.resolve_context,
    0,
    { { "--git-dir", vim.env.DOT_DIR, "--work-tree", vim.env.HOME } }
  )
  if not ok or not work_tree or not git_dir then
    return ""
  end

  -- Integration with gitsigns.nvim
  ---@diagnostic disable-next-line: undefined-field
  local diff = vim.b.gitsigns_status_dict
    or utils.git.diffstat(
      0,
      { "--git-dir", git_dir, "--work-tree", work_tree }
    )
    or {}
  local added = diff.added or 0
  local changed = diff.changed or 0
  local removed = diff.removed or 0
  if added == 0 and removed == 0 and changed == 0 then
    return ""
  end

  local icon_added = utils.stl.escape(vim.trim(icons.GitIconAdd))
  local icon_changed = utils.stl.escape(vim.trim(icons.GitIconChange))
  local icon_removed = utils.stl.escape(vim.trim(icons.GitIconDelete))

  return vim.g.has_nf
      and string.format(
        "%s%s%s",
        utils.stl.hl(icon_added, "StatusLineGitAdded") .. added,
        utils.stl.hl(icon_changed, "StatusLineGitChanged") .. changed,
        utils.stl.hl(icon_removed, "StatusLineGitRemoved") .. removed
      )
    or string.format(
      "%s%s%s",
      icon_added .. utils.stl.hl(tostring(added), "StatusLineGitAdded"),
      icon_changed .. utils.stl.hl(tostring(changed), "StatusLineGitChanged"),
      icon_removed .. utils.stl.hl(tostring(removed), "StatusLineGitRemoved")
    )
end

---Get string representation of current git branch
---@return string
function _G._statusline.gitbranch()
  local ok, work_tree, git_dir = pcall(
    utils.git.resolve_context,
    0,
    { { "--git-dir", vim.env.DOT_DIR, "--work-tree", vim.env.HOME } }
  )
  if not ok or not work_tree or not git_dir then
    return ""
  end

  local use_cur_repo_args = { "--git-dir", git_dir, "--work-tree", work_tree }

  local branch = vim.b.gitsigns_status_dict and vim.b.gitsigns_status_dict.head
    or utils.git.execute(
      0,
      vim.list_extend(
        vim.deepcopy(use_cur_repo_args),
        { "rev-parse", "--abbrev-ref", "HEAD" }
      )
    )
  if not branch then
    return ""
  end

  -- Don't show git branch info if `status.showUntrackedFiles` is 'no'
  -- and current file is not tracked
  -- This prevents showing the dotfiles bare repo branch info in irrelevant
  -- files
  local show_untracked = utils.git.execute(
    0,
    vim.list_extend(vim.deepcopy(use_cur_repo_args), {
      "config",
      "--local",
      "--get",
      "status.showUntrackedFiles",
    })
  )
  local tracked = utils.git.execute(
    0,
    vim.list_extend(
      vim.deepcopy(use_cur_repo_args),
      { "ls-files", vim.api.nvim_buf_get_name(0) }
    )
  )
  if
    (not show_untracked or show_untracked == "no")
    and (not tracked or tracked == "")
  then
    return ""
  end

  local sign_gitbranch = utils.stl.hl(
    utils.stl.escape(vim.trim(icons.GitBranch)),
    "StatusLineGitBranch"
  )
  if vim.g.has_nf then
    sign_gitbranch = sign_gitbranch .. " "
  end

  return sign_gitbranch
    .. utils.stl.escape(str_shorten(branch, gitbranch_max_width))
end

-- Per-server LSP progress tracking
local server_progress = {} -- server_name -> true (busy) or false (done)

-- Servers that don't send LspProgress events (treat as immediately done)
local no_progress_servers = {
  copilot = true,
}

-- Safe redrawstatus helper: swallow Vim-level errors raised by statusline
-- expressions (e.g. E363 from a bad search pattern hitting a long-line
-- buffer) so they never abort the autocmd / timer that triggered them.
local function safe_redrawstatus()
  pcall(vim.cmd.redrawstatus, {
    mods = { emsg_silent = true },
  })
end

-- Track servers by LspAttach/LspDetach
vim.api.nvim_create_autocmd("LspAttach", {
  group = groupid,
  desc = "Track LSP server attachment for statusline.",
  callback = function(args)
    local client = args.data and vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      -- Server attached
      if no_progress_servers[client.name] then
        server_progress[client.name] = false -- done immediately
      else
        server_progress[client.name] = true -- busy, waiting for "end"
      end
      safe_redrawstatus()
    end
  end,
})

vim.api.nvim_create_autocmd("LspDetach", {
  group = groupid,
  desc = "Track LSP server detachment for statusline.",
  callback = function(args)
    local client = args.data and vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      -- Server detached - remove from tracking
      server_progress[client.name] = nil
      safe_redrawstatus()
    end
  end,
})

-- Track completion via LspProgress
vim.api.nvim_create_autocmd("LspProgress", {
  group = groupid,
  desc = "Track LSP progress for statusline.",
  callback = function(args)
    local client = args.data
      and args.data.client_id
      and vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    local kind = args.data
      and args.data.params
      and args.data.params.value
      and args.data.params.value.kind
    if kind == "end" then
      -- Server finished initializing
      server_progress[client.name] = false
      safe_redrawstatus()
    end
  end,
})

-- Animate spinners for busy servers
if _G.LspSpinnerTimer then
  _G.LspSpinnerTimer:stop()
end
_G.LspSpinnerTimer = vim.uv.new_timer()
local spinner_frames =
  { "⣷", "⣯", "⣟", "⡿", "⢿", "⣻", "⣽", "⣾" }
local spinner_idx = 1
_G.LspSpinnerTimer:start(
  0,
  100,
  vim.schedule_wrap(function()
    local has_busy = false
    for _, client in ipairs(vim.lsp.get_clients { bufnr = 0 }) do
      if server_progress[client.name] == true then
        has_busy = true
        break
      end
    end
    if has_busy then
      spinner_idx = (spinner_idx % #spinner_frames) + 1
      safe_redrawstatus()
    end
  end)
)

-- Filetypes that cannot have LSP clients
local lsp_incapable_ft = {
  [""] = true,
  fzf = true,
  help = true,
  qf = true,
  quickfix = true,
  prompt = true,
  noice = true,
  noicefloat = true,
}


---@return string
function _G._statusline.wordcount()
  local stats = nil
  local nwords, nchars = 0, 0 -- luacheck: ignore 311
  if
    vim.b.wc_words
    and vim.b.wc_chars
    and vim.b.wc_changedtick == vim.b.changedtick
  then
    nwords = vim.b.wc_words
    nchars = vim.b.wc_chars
  else
    stats = vim.fn.wordcount()
    nwords = stats.words
    nchars = stats.chars
    vim.b.wc_words = nwords
    vim.b.wc_chars = nchars
    vim.b.wc_changedtick = vim.b.changedtick
  end

  local vwords, vchars = 0, 0
  if vim.fn.mode():find "^[vsVS\x16\x13]" then
    stats = stats or vim.fn.wordcount()
    vwords = stats.visual_words
    vchars = stats.visual_chars
  end

  if nwords == 0 and nchars == 0 then
    return ""
  end

  local vwords_count_str = vwords > 0 and vwords .. "/" or ""
  local vchars_count_str = vchars > 0 and vchars .. "/" or ""
  local words_s_str = nwords > 1 and "s" or ""
  local chars_s_str = nchars > 1 and "s" or ""

  return str_shorten(
    string.format(
      "%s%d word%s, %s%d char%s",
      vwords_count_str,
      nwords,
      words_s_str,
      vchars_count_str,
      nchars,
      chars_s_str
    ),
    wordcount_max_width,
    string.format(
      "%s%dW, %s%dC",
      vwords_count_str,
      nwords,
      vchars_count_str,
      nchars
    )
  )
end

---Record file name of normal buffers, key:val = fname:buffers_with_fname
---@type table<string, number[]>
local fnames = {}

---Update path diffs for buffers with the same file name
---@param bufs integer[]
---@return nil
local function update_pdiffs(bufs)
  bufs = vim.tbl_filter(vim.api.nvim_buf_is_valid, bufs)

  local path_diffs =
    utils.fs.diff(vim.tbl_map(vim.api.nvim_buf_get_name, bufs))

  for i, buf in ipairs(bufs) do
    if path_diffs[i] ~= "" then
      vim.b[buf]._stl_pdiff = path_diffs[i]
    end
  end
end

---Check if buffer is visible
---A buffer is considered visible if it is listed or has a corresponding window
---@param buf integer buffer number
---@return boolean
local function buf_visible(buf)
  return vim.api.nvim_buf_is_valid(buf)
    and (vim.bo[buf].bl or vim.fn.bufwinid(buf) ~= -1)
end

---Add a buffer to `fnames`, calc diff for buffer with non-unique file names
---@param buf integer buffer number
---@return nil
local function add_buf(buf)
  if not buf_visible(buf) then
    return
  end

  local fname = vim.fs.basename(vim.api.nvim_buf_get_name(buf))
  if fname == "" then
    return
  end

  if not fnames[fname] then
    fnames[fname] = {}
  end

  local bufs = fnames[fname] -- buffers with the same name as the removed buf
  if not vim.tbl_contains(bufs, buf) then
    table.insert(bufs, buf)
    update_pdiffs(bufs)
  end
end

---Remove a buffer from `fnames` and update path diffs
---@param buf integer buffer number
---@param bufname string buffer name, `buf` may not be valid so we need this
---@return nil
local function remove_buf(buf, bufname)
  if buf_visible(buf) then
    return
  end

  bufname = vim.fs.basename(bufname)
  local bufs = fnames[bufname] -- buffers with the same name as the removed buf
  if not bufs then
    return
  end

  for i, b in ipairs(bufs) do
    if b == buf then
      table.remove(bufs, i)
      break
    end
  end

  local num_bufs = #bufs
  if num_bufs == 0 then
    fnames[bufname] = nil
    return
  end

  if num_bufs == 1 then
    if vim.api.nvim_buf_is_valid(bufs[1]) then
      vim.b[bufs[1]]._stl_pdiff = nil
    end
    return
  end

  -- Still have multiple buffers with the same file name,
  -- update path diffs for the remaining buffers
  update_pdiffs(bufs)
end

for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  add_buf(buf)
end

vim.api.nvim_create_autocmd({ "BufAdd", "BufWinEnter", "BufFilePost" }, {
  desc = "Track new buffer file name.",
  group = groupid,
  -- Delay adding buffer to fnames to ensure attributes, e.g.
  -- `bt`, are set for special buffers, for example, terminal buffers
  callback = vim.schedule_wrap(function(args)
    add_buf(args.buf)
    pcall(vim.cmd.redrawstatus, {
      bang = true,
      mods = { emsg_silent = true },
    })
  end),
})

vim.api.nvim_create_autocmd("OptionSet", {
  desc = "Remove invisible buffer record.",
  group = groupid,
  pattern = "buflisted",
  callback = function(args)
    remove_buf(args.buf, args.file)
    -- For some reason, invoking `:redrawstatus` directly makes oil.nvim open
    -- a floating window shortly before opening a file
    vim.schedule(function()
      pcall(vim.cmd.redrawstatus, {
        bang = true,
        mods = { emsg_silent = true },
      })
    end)
  end,
})

vim.api.nvim_create_autocmd({
  "BufLeave",
  "BufHidden",
  "BufDelete",
  "BufFilePre",
}, {
  desc = "Remove invisible buffer from record.",
  group = groupid,
  callback = vim.schedule_wrap(function(args)
    remove_buf(args.buf, args.file)
  end),
})

vim.api.nvim_create_autocmd("WinClosed", {
  group = groupid,
  callback = function(args)
    local win = tonumber(args.match)
    if not win or not vim.api.nvim_win_is_valid(win) then
      return
    end
    local buf = vim.api.nvim_win_get_buf(win)
    local bufname = vim.api.nvim_buf_get_name(buf)
    vim.schedule(function()
      remove_buf(buf, bufname)
    end)
  end,
})



local function filepath()
  local bufname = vim.api.nvim_buf_get_name(0)
  local absolute_path = bufname:gsub("^oil://", "")

  -- Oil buffer: show path relative to project root
  if vim.bo.filetype == "oil" and absolute_path ~= "" then
    local project_root = utils.fs.cwd_dir(absolute_path)
    if project_root then
      local project_parent = vim.fs.dirname(project_root)
      return absolute_path:gsub("^" .. vim.pesc(project_parent) .. "/", "")
    else
      return vim.fn.fnamemodify(absolute_path, ":~")
    end
  end

  local fpath = vim.fn.fnamemodify(vim.fn.expand "%", ":~:.:h")
  if fpath == "" or fpath == "." then
    return ""
  end
  return fpath .. "/"
end

---@return string
function _G._statusline.fname()
  local bufname = vim.api.nvim_buf_get_name(0)
  local fname_root = vim.fn.fnamemodify(bufname, ":t:r")
  local fname_ext = vim.fn.fnamemodify(bufname, ":e")
  local fname_short = string.format(
    "%s%s%s",
    str_shorten(fname_root, fname_max_width),
    fname_root ~= "" and fname_ext ~= "" and "." or "",
    str_shorten(fname_ext, fname_ext_max_width)
  )

  local fpath = filepath()

  -- Oil buffer: only show path, no filename
  if vim.bo.filetype == "oil" then
    return fpath
  end

  -- Modified and readonly icons
  local file_indicator = ""
  if vim.bo.modified then
    file_indicator = " ● "
  elseif vim.bo.readonly or not vim.bo.modifiable then
    file_indicator = " 🔒 "
  end

  -- Normal buffer
  if vim.bo.bt == "" then
    -- Unnamed normal buffer
    if bufname == "" then
      return "[Buffer %n]"
    end
    -- Named normal buffer, show path + file name with different highlights
    if fpath ~= "" then
      local diag_hl = get_diagnostic_hl()
      return string.format(
        "%%#StatusLineDimmed#%s%%#" .. diag_hl .. "#%s%s",
        fpath,
        fname_short,
        file_indicator
      )
    end
    return string.format(
      "%%#%s#%s%s",
      get_diagnostic_hl(),
      fname_short,
      file_indicator
    )
  end

  if vim.bo.bt == "quickfix" then
    return utils.stl.escape(
      str_shorten(vim.w.quickfix_title, fname_special_max_width)
    ) or ""
  end

  -- Terminal buffer, show terminal command and id
  if vim.bo.bt == "terminal" then
    local path, pid, cmd, comment = utils.term.parse_name(bufname)
    if not path or not pid or not cmd then
      return string.format(
        "[Terminal] %s",
        str_shorten(bufname, fname_max_width)
      )
    end
    return string.format(
      "[Terminal %s] %s [%s]",
      utils.stl.escape(
        str_shorten(
          comment ~= "" and comment or pid,
          fname_prefix_suffix_max_width
        )
      ),
      utils.stl.escape(str_shorten(cmd, fname_max_width)),
      utils.stl.escape(
        str_shorten(
          vim.fn.fnamemodify(path, ":~"):gsub("/+$", ""),
          fname_prefix_suffix_max_width
        )
      )
    )
  end

  -- Other special buffer types
  local prefix, main = bufname:match "^%s*(%S+)://(.*)"
  if prefix and main then
    return utils.stl.escape(
      string.format(
        "[%s] %s",
        str_shorten(
          utils.str.snake_to_pascal(vim.fs.basename(prefix)) --[[@as string]],
          fname_prefix_suffix_max_width
        ),
        str_shorten(main, fname_special_max_width)
      )
    )
  end

  return utils.stl.escape(
    str_shorten(
      vim.api.nvim_eval_statusline("%F", {}).str,
      fname_special_max_width
    )
  )
end

---Name of python virtual environment
---@return string
function _G._statusline.venv()
  local venv_name = vim.env.VIRTUAL_ENV
      and vim.fn.fnamemodify(vim.env.VIRTUAL_ENV, ":~:.")
    or vim.env.CONDA_DEFAULT_ENV
  return venv_name and string.format("venv: %s", venv_name) or ""
end

---Text filetypes
---@type table<string, true>
local is_text = {
  [""] = true,
  ["tex"] = true,
  ["markdown"] = true,
  ["text"] = true,
}

---Check if current buffer is a python/jupyter notebook buffer
---@return boolean
local function is_python()
  return vim.startswith(vim.bo.ft, "python")
    or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":e") == "ipynb"
end

---Additional info for the current buffer enclosed in parentheses
---@return string
function _G._statusline.info()
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

  add_section(_G._statusline.ft())

  if is_text[vim.bo.ft] and not vim.b.bigfile then
    add_section(_G._statusline.wordcount())
  end

  if is_python() then
    add_section(_G._statusline.venv())
  end

  add_section(_G._statusline.gitbranch())
  add_section(_G._statusline.gitdiff())
  return vim.tbl_isempty(info) and ""
    or string.format("(%s) ", table.concat(info, ", "))
end

vim.api.nvim_create_autocmd("DiagnosticChanged", {
  group = groupid,
  desc = "Update diagnostics cache for the status line.",
  callback = function(args)
    vim.b[args.buf].diag_cnt_cache = vim.diagnostic.count(args.buf)
    vim.b[args.buf].diag_str_cache = nil
    pcall(vim.cmd.redrawstatus, {
      mods = { emsg_silent = true },
    })
  end,
})

---Get string representation of diagnostics for current buffer
---@return string
function _G._statusline.diag()
  if vim.b.diag_str_cache then
    return vim.b.diag_str_cache
  end
  local str = ""
  local buf_cnt = vim.b.diag_cnt_cache or {}
  for serverity_nr, severity in ipairs { "Error", "Warn", "INFO", "Hint" } do
    local cnt = buf_cnt[serverity_nr] ~= vim.NIL and buf_cnt[serverity_nr] or 0
    if cnt > 0 then
      local icon_text = get_diag_sign_text(serverity_nr)
      local icon_hl = "StatusLineDiagnostic" .. severity
      str = str
        .. (str == "" and "" or " ")
        .. utils.stl.hl(icon_text, icon_hl)
        .. cnt
    end
  end
  if str:find "%S" then
    str = str .. " "
  end
  vim.b.diag_str_cache = str
  return str
end

---Get current filetype
---@return string
function _G._statusline.ft()
  local ft = string.format(
    " %s %s ",
    utils.general.icon_provider(0),
    vim.bo.ft:gsub("^%l", string.upper)
  )
  return vim.bo.ft == "" and "" or utils.stl.hl(ft, "StatusLineDimmed")
end

---LSP server names with per-server indicators
---Shows: "copilot ⣷, lua_ls 󰄬" (spinner when busy, tick when done)
---@return string
function _G._statusline.lsp_status()
  local ft = vim.bo.filetype or ""
  if lsp_incapable_ft[ft] or vim.bo.bt == "nofile" then
    return ""
  end

  local clients = vim.lsp.get_clients { bufnr = 0 }
  if #clients == 0 then
    return ""
  end

  local parts = {}
  local all_done = true

  for _, client in ipairs(clients) do
    local is_busy = server_progress[client.name] == true
    if is_busy then
      all_done = false
    end

    local indicator
    if is_busy then
      indicator =
        string.format("%%#LspSpinner#%s%%*", spinner_frames[spinner_idx])
    else
      indicator = string.format("%%#LspReady#%s%%*", "󰄬 ")
    end

    local server_name = utils.stl.hl(client.name, "StatusLineDimmed")
    table.insert(parts, string.format("%s %s", server_name, indicator))
  end

  local result = table.concat(parts, ", ")

  if all_done then
    return string.format(
      "%s %s",
      result,
      string.format("%%#LspConnected#%s%%* ", icons.diagnostics.Connected)
    )
  end

  return result
end

-- stylua: ignore start
---Build statusline using pure Lua (no %{} expressions)
---@return string
function _G._statusline.build()
  local stl_parts = {
    _G._statusline.mode(),
    _G._statusline.project_name(),
    ' ',
    _G._statusline.fname(),
    ' ',
    _G._statusline.search_count(),
    ' ',
    _G._statusline.macro(),
    '%=',
    _G._statusline.gitbranch(),
    _G._statusline.gitdiff(),
    ' ',
    _G._statusline.lsp_status(),
    _G._statusline.treesitter_status(),
    _G._statusline.ft(),
    ' ',
    _G._statusline.diag(),
    _G._statusline.pos(),
  }
  return table.concat(stl_parts)
end

---Build statusline for non-current windows
---@return string
function _G._statusline.build_nc()
  local stl_parts = {
    ' ',
    _G._statusline.project_name(),
    ' ',
    _G._statusline.fname(),
    '%=',
    _G._statusline.pos(),
  }
  return table.concat(stl_parts)
end

-- Flag component (pure Lua version)
function _G._statusline.flag()
  local bt = vim.bo.bt
  if bt == '' then
    return ''
  elseif bt == 'help' then
    return '%h '
  elseif bt == 'preview' then
    return '%w '
  elseif bt == 'quickfix' then
    return '%q '
  end
  return ''
end

-- Position component (pure Lua version)
function _G._statusline.pos()
  if vim.opt.relativenumber:get() then
    local l = vim.fn.line('.')
    local c = vim.fn.col('.')
    return string.format('%%l:%%c ', l, c)
  elseif vim.opt.number:get() then
    return string.format('%%l:%%c ', vim.fn.line('.'), vim.fn.col('.'))
  end
  return ''
end

-- Project name component
function _G._statusline.project_name()
  local icon = '󰉋 '
  local name = ''
  local buf = vim.api.nvim_get_current_buf()
  local buf_name = vim.api.nvim_buf_get_name(buf)

  if buf_name ~= '' and vim.bo[buf].buftype == '' or vim.bo[buf].filetype == 'oil' then
    local clean_path = buf_name:gsub('^oil://', '')
    local root = utils.fs.cwd_dir(clean_path)
    if root then
      name = vim.fn.fnamemodify(root, ':t')
    end
  end

  if name == '' then
    name = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
  end

  return utils.stl.hl(string.format('%s%s ', icon, name), 'StatusLineDimmed')
end

-- Search count component
--
-- `vim.fn.searchcount()` evaluates the current search pattern (@/) against
-- the buffer. With a complex/pathological pattern + long lines this blows
-- `maxmempattern` and raises E363, which then aborts the entire
-- `redrawstatus` (and any autocmd that triggered it, e.g. LspAttach).
--
-- Guards:
--   1. Skip on `bigfile` buffers (consistent with wordcount() upstream).
--   2. Skip when the current line is excessively long, since searchcount
--      tends to choke proportionally to the longest matched run.
--   3. Bound the timeout aggressively so a slow regex on any buffer doesn't
--      stall the UI.
--   4. pcall the whole call so a Vim-level regex error (E363, E383, etc.)
--      degrades gracefully instead of breaking the statusline.
function _G._statusline.search_count()
  if vim.v.hlsearch == 0 then
    return ''
  end

  if vim.b.bigfile then
    return ''
  end

  -- Cheap structural check: if the file is huge or any line is enormous,
  -- searchcount will be slow at best and crash at worst.
  local line_count = vim.api.nvim_buf_line_count(0)
  if line_count > 50000 then
    return ''
  end
  local longest = vim.fn.strdisplaywidth(vim.fn.getline('.') or '')
  if longest > 5000 then
    return ''
  end

  local ok, result = pcall(vim.fn.searchcount, { maxcount = 999, timeout = 100 })
  if
    not ok
    or type(result) ~= 'table'
    or next(result) == nil
    or result.incomplete == 1
    or (result.total or 0) == 0
  then
    return ''
  end

  return string.format(
    '[%d/%d]',
    result.current or 0,
    math.min(result.total, result.maxcount or result.total)
  )
end

function _G._statusline.section_location()
  return '%2l:%-2v'
end

function _G._statusline.cursor_pos()
  local curr_line = vim.api.nvim_win_get_cursor(0)[1]
  local total_lines = vim.api.nvim_buf_line_count(0)

  if total_lines == 0 then
    return ' 0%%%% '
  end

  if curr_line == 1 then
    return 'Top '
  elseif curr_line == total_lines then
    return 'Bot '
  end

  local percentage = math.floor((curr_line / total_lines) * 100)
  return utils.stl.hl(
    string.format('%2d%%%% ', percentage),
    'StatusLineHeader'
  )
end

function _G._statusline.line_info()
  if vim.bo.filetype == 'alpha' then
    return ''
  end

  return utils.stl.hl(
    string.format(
      ' %s %s',
      _G._statusline.section_location(),
      _G._statusline.cursor_pos()
    ),
    'StatusLineHeader'
  )
end

-- Macro recording component
function _G._statusline.macro()
  local recording_register = vim.fn.reg_recording()
  if recording_register == '' then
    return ''
  else
    return 'Recording @' .. recording_register .. ' '
  end
end

-- Treesitter status component
function _G._statusline.treesitter_status()
  local buf = vim.api.nvim_get_current_buf()

  if vim.bo[buf].buftype ~= '' or vim.bo[buf].filetype == '' then
    return ''
  end

  local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype) or vim.bo[buf].filetype
  if lang then
    local success = pcall(vim.treesitter.get_parser, buf, lang)
    if success then
      return utils.stl.hl(' TS', 'StatusLineDimmed')
    end
  end
  return ''
end



-- stylua: ignore start
---Statusline components
---@type table<string, string>
local components = {
  align     = [[%=]],
  flag      = [[%{%&bt==#''?'':(&bt==#'help'?'%h ':(&pvw?'%w ':(&bt==#'quickfix'?'%q ':'')))%}]],
  diag      = [[%{%v:lua._statusline.diag()%}]],
  root      = [[%{%v:lua._statusline.project_name()%}]],
  fname     = [[%{%v:lua._statusline.fname()%} ]],
  args      = [[%{%v:lua._statusline.info()%}]],
  lsp_status = [[%{%v:lua._statusline.lsp_status()%}]],
  mode      = [[%{%v:lua._statusline.mode()%}]],
  padding   = [[ ]],
  pos       = [[%{%&ru?(((!&nu&&!&rnu)?"%l:%c ":"")."%P "):""%}]],
  truncate  = [[%<]],
  gitbranch = [[%{%v:lua._statusline.gitbranch()%} ]],
  gitdiff   = [[%{%v:lua._statusline.gitdiff()%}]],
  search    = [[%{%v:lua._statusline.search_count()%} ]],
  macro     = [[%{%v:lua._statusline.macro()%}]],
  treesitter = [[%{%v:lua._statusline.treesitter_status()%} ]],

  ft        = [[%{%v:lua._statusline.ft()%} ]],
  lineinfo  = [[%{%v:lua._statusline.line_info()%} ]],
}
-- stylua: ignore end

local stl = table.concat {
  components.mode,
  components.flag,
  components.root,
  components.fname,
  components.diag,
  components.search,
  components.macro,
  components.align,
  components.lsp_status,
  components.gitbranch,
  components.gitdiff,
  components.treesitter,
  components.ft,
  components.truncate,
  components.lineinfo,
}

local stl_nc = table.concat {
  components.padding,
  components.flag,
  components.root,
  components.fname,
  components.align,
  components.truncate,
  components.pos,
}

setmetatable(_G._statusline, {
  ---Get statusline string
  ---@return string
  __call = function()
    return vim.g.statusline_winid == vim.api.nvim_get_current_win() and stl
      or stl_nc
  end,
})

-- Prevent statusline from being overridden by qf ftplugin in quickfix windows
vim.g.qf_disable_statusline = true

utils.hl.persist(function()
  -- stylua: ignore start
  utils.hl.set(0, 'StatusLineGitBranch',       { link = 'StatusLineGitChanged', default = true })
  utils.hl.set(0, 'StatusLineGitAdded',        { link = 'GitSignsAdd',          default = true })
  utils.hl.set(0, 'StatusLineGitChanged',      { link = 'GitSignsChange',       default = true })
  utils.hl.set(0, 'StatusLineGitRemoved',      { link = 'GitSignsDelete',       default = true })
  utils.hl.set(0, 'StatusLineDiagnosticHint',  { link = 'DiagnosticSignHint',   default = true })
  utils.hl.set(0, 'StatusLineDiagnosticInfo',  { link = 'DiagnosticSignInfo',   default = true })
  utils.hl.set(0, 'StatusLineDiagnosticWarn',  { link = 'DiagnosticSignWarn',   default = true })
  utils.hl.set(0, 'StatusLineDiagnosticError', { link = 'DiagnosticSignError',  default = true })
  utils.hl.set(0, 'LspConnected', { fg = 'green', default = true })

  utils.hl.set(0, 'StatusLineHeader',          { fg = 'TabLine', bg = 'fg', ctermfg = 'TabLine', ctermbg = 'fg', reverse = true, default = true })
  utils.hl.set(0, 'StatusLineHeaderModified',  { fg = 'Special', bg = 'fg', ctermfg = 'Special', ctermbg = 'fg', reverse = true, default = true })
  -- stylua: ignore end
end)

return _G._statusline
