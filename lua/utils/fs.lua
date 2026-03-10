local M = {}

M.root_markers = {
  -- Must include python environment root markers here so that we can set cwd
  -- inside a python project and have correct python version in nvim.
  -- This is crucial for running pytest from within nvim using vim-test or
  -- other jobs that requires a python virtual environment.
  { 'venv', 'env', '.venv', '.env' },
  { '.python-version' },
  {
    '.git',
    '.svn',
    '.bzr',
    '.hg',
  },
  {
    '.project',
    '.pro',
    '.sln',
    '.vcxproj',
  },
  {
    'Makefile',
    'makefile',
    'MAKEFILE',
  },
  {
    '.gitignore',
    '.editorconfig',
  },
  {
    'README',
    'README.md',
    'README.txt',
    'README.org',
  },
}

local fs_root = vim.fs.root

---Wrapper of `vim.fs.root()` that accepts layered root markers like
---`vim.lsp.Config.root_markers`
---@param source? integer|string default to current working directory
---@param marker? (string|string[]|string[][]|fun(name: string, path: string): boolean) default to `utils.fs.root_markers`
---@return string?
function M.root(source, marker)
  source = source or 0
  marker = marker or M.root_markers

  if type(marker) ~= 'table' then
    return fs_root(source, marker)
  end

  local joined_markers = {} ---@type string[]

  for _, m in ipairs(marker) do
    -- `m` is a string, join with previous string markers as they are
    -- considered to have the same priority
    if type(m) == 'string' then
      table.insert(joined_markers, m)
      goto continue
    end

    -- `m` is a set of markers of the same priority, search them directly
    -- with `vim.fs.root()`, but before that we have to deal with previous
    -- unresolved marker set
    if not vim.tbl_isempty(joined_markers) then
      local root = fs_root(source, joined_markers)
      joined_markers = {}
      if root then
        return root
      end
    end

    local root = fs_root(source, m)
    if root then
      return root
    end
    ::continue::
  end
end

---Read file contents
---@param path string
---@return string?
function M.read_file(path)
  local file = io.open(path, 'r')
  if not file then
    return nil
  end
  local content = file:read('*a')
  file:close()
  return content or ''
end

---Write string into file
---@param path string
---@return boolean success
function M.write_file(path, str)
  local file = io.open(path, 'w')
  if not file then
    return false
  end
  file:write(str)
  file:close()
  return true
end

---Check if a path is empty
---@param path string
---@return boolean
function M.is_empty(path)
  local stat = vim.uv.fs_stat(path)
  return not stat or stat.size == 0
end

---Given a list of paths, return a list of path heads that uniquely distinguish each path
---e.g. { 'a/b/c', 'a/b/d', 'a/e/f' } -> { 'c', 'd', 'f' }
---     { 'a/b/c', 'd/b/c', 'e/c' } -> { 'a/b', 'd/b', 'e' }
---@param paths string[]
---@return string[]
function M.diff(paths)
  local n_paths = (function()
    local path_set = {}
    for _, path in ipairs(paths) do
      path_set[path] = true
    end
    return #vim.tbl_keys(path_set)
  end)()

  ---@alias ipath { [1]: string, [2]: integer }
  ---Paths with index
  ---@type ipath[]
  local ipaths = {}
  for i, path in ipairs(paths) do
    table.insert(ipaths, { path, i })
  end

  ---Groups of paths with the same tail
  ---key:val = tail:ihead[]
  ---@type table<string, ipath[]>
  local groups = { [''] = ipaths }

  while #vim.tbl_keys(groups) < n_paths do
    local g = {} ---@type table<string, ipath[]>
    for tail, iheads in pairs(groups) do
      for _, ihead in ipairs(iheads) do
        local head = ihead[1]
        local idx = ihead[2]
        local t = vim.fn.fnamemodify(head, ':t')
        local h = vim.fn.fnamemodify(head, ':h')
        if #vim.tbl_keys(groups) > 1 then
          t = t == '' and tail or tail == '' and t or vim.fs.joinpath(t, tail)
        end
        h = h == '.' and '' or h

        if not g[t] then
          g[t] = {}
        end
        table.insert(g[t], { h, idx })
      end
    end
    groups = g
  end

  local diffs = {}
  for tail, iheads in pairs(groups) do
    for _, ihead in ipairs(iheads) do
      diffs[ihead[2]] = tail
    end
  end
  return diffs
end

---Check if a given directory contains a file or subdirectory
---@param parent string directory path
---@param sub string sub file or directory path
---@param strict? boolean whether to return false if `parent` == `sub`, default false
function M.contains(parent, sub, strict)
  -- `fnamemodify()` adds trailing `/` to directories
  -- `parent` must end with `/`, else when `sub` is `/foo/bar-baz/file.txt` and
  -- `parent` is `/foo/bar`, the function gives false positive
  parent = vim.fn.fnamemodify(vim.fs.normalize(parent), ':p')
  sub = vim.fn.fnamemodify(vim.fs.normalize(sub), ':p')
  if strict and parent == sub then
    return false
  end
  return vim.startswith(sub, parent)
end

---Check if given directory is root directory
---@param dir string
---@return boolean
function M.is_root_dir(dir)
  return dir == vim.fs.dirname(dir)
end

function M.is_git_repo()
  vim.fn.system('git rev-parse --is-inside-work-tree')

  return vim.v.shell_error == 0
end

---Home directory
---@type string?
local home

---Check if given directory is home directory
---@param dir string
---@return boolean
function M.is_home_dir(dir)
  if not home then
    home = vim.uv.os_homedir()
    home = home and vim.fs.normalize(home)
  end
  return vim.fs.normalize(dir) == home
end

---Check if a path is full path
---@param path string
---@return boolean
function M.is_full_path(path)
  -- Use `fs.normalize()` to trim trailing slashes so that
  -- `foo/` and `foo` are treated equally
  return vim.fs.normalize(vim.fn.fnamemodify(path, ':p'))
    == vim.fs.normalize(path)
end

function M.is_new_file()
  local filename = vim.fn.expand('%')
  return filename ~= ''
    and vim.bo.buftype == ''
    and vim.fn.filereadable(filename) == 0
end

function M.get_project_path()
  local full_path = vim.api.nvim_buf_get_name(0)
  if full_path == '' then
    return '[No Name]'
  end

  local git_root = vim.fs.root(0, '.git')

  if not git_root then
    return vim.fn.fnamemodify(full_path, ':.')
  end

  local project_name = vim.fn.fnamemodify(git_root, ':t')
  local rel_to_root = vim.fn.fnamemodify(full_path, ':p'):sub(#git_root + 2)
  return project_name .. '/' .. rel_to_root
end

function M.get_filename()
  local current = vim.api.nvim_get_current_win()
  local filename = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(current))
  local icon = ''
  local icon_highlight = ''

  if filename ~= '' then
    local devicons_present, devicons = pcall(require, 'nvim-web-devicons')

    if devicons_present then
      local ft_icon, icon_hl = devicons.get_icon(filename)
      icon = (ft_icon ~= nil and ft_icon) or icon
      icon_highlight = icon_hl
    end
    filename = vim.fn.fnamemodify(filename, ':~:.')
    filename = string.format('%s%s', icon .. ' ', filename)
  else
    filename = string.format(' %s%s ', icon, vim.bo.filetype):upper()
  end

  return filename, icon_highlight
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
    local shortened = segment:sub(1, vim.startswith(segment, '.') and 2 or 1)
    segments[idx] = shortened
    len = len - (#segment - #shortened)
  end

  return table.concat(segments, sep)
end

---Compute project directory for given path.
---@param path string?
---@param patterns string[]? root patterns
---@return string? nil if not found
function M.cwd_dir(path, patterns)
  if not path or path == '' then
    return nil
  end

  path = path:gsub('^oil://', ''):gsub('/$', '')

  patterns = patterns or M.root_markers

  local stat = vim.uv.fs_stat(path)
  if not stat then
    return nil
  end

  local start_dir = stat.type == 'directory' and path or vim.fs.dirname(path)

  for _, group in ipairs(patterns or {}) do
    local matches = vim.fs.find(group, {
      path = start_dir,
      upward = true,
      stop = vim.uv.os_homedir(),
    })

    if matches[1] then
      local root = vim.fs.dirname(matches[1])
      return vim.uv.fs_realpath(root)
    end
  end

  return nil
end

---@param base string
---@param path string
---@return string
function M.relative(base, path)
  local n_base = vim.fs.normalize(base)
  local n_path = vim.fs.normalize(path)

  if n_path == n_base then
    return '.'
  end

  if not n_base:match('[/\\]$') then
    n_base = n_base .. '/'
  end

  if n_path:find('^' .. vim.pesc(n_base), 1, true) then
    return n_path:sub(#n_base + 1)
  end

  return path
end

return M
