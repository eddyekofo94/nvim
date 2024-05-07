local M = {}

local utils = require "utils.general"
local get_icon = require "utils.static.icons"

M.root_patterns = {
  ".git/",
  ".svn/",
  ".bzr/",
  ".hg/",
  ".project/",
  ".pro",
  ".sln",
  ".vcxproj",
  "Makefile",
  "makefile",
  "MAKEFILE",
  ".gitignore",
  ".editorconfig",
}

function M.get_root()
  ---@type string?
  local path = vim.api.nvim_buf_get_name(0)
  path = path ~= "" and vim.loop.fs_realpath(path) or nil
  ---@type string[]
  local roots = {}
  if path then
    for _, client in pairs(vim.lsp.get_clients { bufnr = 0 }) do
      local workspace = client.config.workspace_folders
      local paths = workspace
          and vim.tbl_map(function(ws)
            return vim.uri_to_fname(ws.uri)
          end, workspace)
        or client.config.root_dir and { client.config.root_dir }
        or {}
      for _, p in ipairs(paths) do
        local r = vim.loop.fs_realpath(p)
        if path:find(r, 1, true) then
          roots[#roots + 1] = r
        end
      end
    end
  end
  table.sort(roots, function(a, b)
    return #a > #b
  end)

  ---@type string?
  local root = roots[1]
  if not root then
    path = path and vim.fs.dirname(path) or vim.uv.cwd()
    ---@type string?
    root = vim.fs.find(M.root_patterns, { path = path, upward = true })[1]
    root = root and vim.fs.dirname(root) or vim.uv.cwd()
  end
  ---@cast root string
  return root
end

local git = { url = "https://github.com/" }
local NVIM_PATH = vim.fn.stdpath "config"

--- Run a git command from the AstroNvim installation directory
---@param args string|string[] the git arguments
---@return string|nil # The result of the command or nil if unsuccessful
function git.cmd(args, ...)
  if type(args) == "string" then
    args = { args }
  end
  return utils.cmd(vim.list_extend({ "git", "-C", NVIM_PATH }, args), ...)
end

--- Check if the AstroNvim home is a git repo
---@return string|nil # The result of the command
function M.is_git_repo()
  return git.cmd({ "rev-parse", "--is-inside-work-tree" }, false)
end

-- We cache the results of "git rev-parse"
-- Process creation is expensive in Windows, so this reduces latency
-- local is_inside_work_tree = {}

-- function M.is_git_repo()
--   local cwd = vim.fn.getcwd()
--   if is_inside_work_tree[cwd] == nil then
--     vim.fn.system "git rev-parse --is-inside-work-tree"
--     is_inside_work_tree[cwd] = vim.v.shell_error == 0
--   end
--
--   return is_inside_work_tree[cwd]
-- end

function M.filename()
  local current = vim.api.nvim_get_current_win()
  local filename = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(current))
  local icon = ""

  if filename ~= "" then
    local devicons_present, devicons = pcall(require, "nvim-web-devicons")

    if devicons_present then
      local ft_icon = devicons.get_icon(filename)
      icon = (ft_icon ~= nil and ft_icon) or icon
    end
    filename = vim.fn.fnamemodify(filename, ":~:.")
    filename = string.format("%s%s", icon .. " ", filename)
  else
    filename = icon .. "[No Name]"
  end

  return filename
end

-- INFO: returns if there's a git directory
function M.git_root_dir(...)
  local root_dir
  for dir in vim.fs.parents(vim.api.nvim_buf_get_name(0)) do
    if vim.fn.isdirectory(dir .. "/.git") == 1 then
      root_dir = dir
      break
    end
  end

  return root_dir
end

---Compute project directory for given path.
---@param path string?
---@param patterns string[]? root patterns
---@return string? nil if not found
function M.proj_dir(path, patterns)
  if not path or path == "" then
    return nil
  end
  patterns = patterns or M.root_patterns
  ---@diagnostic disable-next-line: undefined-field
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return
  end
  local dirpath = stat.type == "directory" and path or vim.fs.dirname(path)
  for _, pattern in ipairs(patterns) do
    local root = vim.fs.find(pattern, {
      path = dirpath,
      upward = true,
      type = pattern:match "/$" and "directory" or "file",
    })[1]
    if root and vim.uv.fs_stat(root) then
      local dirname = vim.fs.dirname(root)
      return dirname and vim.uv.fs_realpath(dirname) --[[@as string]]
    end
  end
end

---Read file contents
---@param path string
---@return string?
function M.read_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local content = file:read "*a"
  file:close()
  return content or ""
end

---Write string into file
---@param path string
---@return boolean success
function M.write_file(path, str)
  local file = io.open(path, "w")
  if not file then
    return false
  end
  file:write(str)
  file:close()
  return true
end

function M.is_new_file()
  local filename = vim.fn.expand "%"
  return filename ~= "" and vim.bo.buftype == "" and vim.fn.filereadable(filename) == 0
end

-- Get unique name for the current buffer
function M.get_unique_filename(filename, shorten)
  local get_current_filenames = require("utils.buffer").get_current_filenames

  local filenames = vim.tbl_filter(function(filename_other)
    return filename_other ~= filename
  end, get_current_filenames())

  if shorten then
    filename = fn.pathshorten(filename)
    filenames = vim.tbl_map(fn.pathshorten, filenames)
  end

  -- Reverse filenames in order to compare their names
  filename = string.reverse(filename)
  filenames = vim.tbl_map(string.reverse, filenames)

  local index

  -- For every other filename, compare it with the name of the current file char-by-char to
  -- find the minimum index `i` where the i-th character is different for the two filenames
  -- After doing it for every filename, get the maximum value of `i`
  if next(filenames) then
    index = math.max(unpack(vim.tbl_map(function(filename_other)
      for i = 1, #filename do
        -- Compare i-th character of both names until they aren't equal
        if filename:sub(i, i) ~= filename_other:sub(i, i) then
          return i
        end
      end
      return 1
    end, filenames)))
  else
    index = 1
  end

  -- Iterate backwards (since filename is reversed) until a "/" is found
  -- in order to show a valid file path
  while index <= #filename do
    if filename:sub(index, index) == "/" then
      index = index - 1
      break
    end

    index = index + 1
  end

  return string.reverse(string.sub(filename, 1, index))
end

---@param path string
---@param sep string path separator
---@param max_len integer maximum length of the full filename string
---@return string
function M.shorten_path(path, sep, max_len)
  local len = #path
  if len <= max_len then
    return path
  end

  local segments = vim.split(path, sep)

  if M.is_git_repo() and max_len == 0 then
    return segments[#segments]
  end

  for idx = 1, #segments - 1 do
    if len <= max_len then
      break
    end

    local segment = segments[idx]
    local shortened = segment:sub(1, vim.startswith(segment, ".") and 2 or 1)
    segments[idx] = shortened
    len = len - (#segment - #shortened)
  end

  return table.concat(segments, sep)
end

--- Get a unique filepath between all buffers
---@param opts? table options for function to get the buffer name, a buffer number, max length, and options passed to the stylize function
---@return function # path to file that uniquely identifies each buffer
-- @usage local heirline_component = { provider = require("astronvim.utils.status").provider.unique_path() }
-- @see astronvim.utils.status.utils.stylize
function M.unique_path(opts)
  opts = utils.extend_tbl({
    buf_name = function(bufnr)
      return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")
    end,
    bufnr = 0,
    max_length = 16,
  }, opts)
  local function path_parts(bufnr)
    local parts = {}
    for match in (vim.api.nvim_buf_get_name(bufnr) .. "/"):gmatch("(.-)" .. "/") do
      table.insert(parts, match)
    end
    return parts
  end
  return function(self)
    opts.bufnr = self and self.bufnr or opts.bufnr
    local name = opts.buf_name(opts.bufnr)
    local unique_path = ""
    -- check for same buffer names under different dirs
    local current
    for _, value in ipairs(vim.t.bufs or {}) do
      if name == opts.buf_name(value) and value ~= opts.bufnr then
        if not current then
          current = path_parts(opts.bufnr)
        end
        local other = path_parts(value)

        for i = #current - 1, 1, -1 do
          if current[i] ~= other[i] then
            unique_path = current[i] .. "/"
            break
          end
        end
      end
    end
    return utils.stylise(
      (
        opts.max_length > 0
        and #unique_path > opts.max_length
        and string.sub(unique_path, 1, opts.max_length - 2) .. get_icon "Ellipsis" .. "/"
      ) or unique_path,
      opts
    )
  end
end

return M
