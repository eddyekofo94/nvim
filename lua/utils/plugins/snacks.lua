local M = {}
local utils_fs = require "utils.fs"

function M.pick(source, opts)
  local params = { builtin = source, opts = opts }
  return function()
    if opts.dirs ~= vim.uv.cwd() then
      source = params.builtin
      opts = params.opts
      opts = vim.tbl_deep_extend("force", { dirs = utils_fs:get_root() }, opts or {})
    end

    Snacks.picker.pick(source, opts)
  end
end

function M.dotfiles()
  return Snacks.picker.files { cwd = os.getenv "HOME" .. "/.dotfiles/" }
  -- return M.pick("files", { dirs = os.getenv "HOME" .. "/.dotfiles/", follow = true, hidden = true })
end

return M
