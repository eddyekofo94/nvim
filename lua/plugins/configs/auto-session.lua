local opts = {
  log_level = "error",
  auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
  auto_session_enable_last_session = true,
  auto_session_root_dir = vim.fn.stdpath "data" .. "/sessions/",
  auto_session_enabled = true,
  auto_save_enabled = true,
  auto_restore_enabled = true,
  auto_session_use_git_branch = nil,
  bypass_session_save_file_types = nil,
  cwd_change_handling = {
    restore_upcoming_session = false, -- already the default, no need to specify like this, only here as an example
    pre_cwd_changed_hook = nil, -- already the default, no need to specify like this, only here as an example
    -- post_cwd_changed_hook = function() -- example refreshing the lualine status line _after_ the cwd changes
    --   require("lualine").refresh() -- refresh lualine so the new session name is displayed in the status bar
    -- end,
  },
}

require("auto-session").setup(opts)
