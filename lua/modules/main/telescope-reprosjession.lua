return {
  "MikaelElkiaer/telescope-reprosjession",
  enabled = false,
  requires = {
    "telescope.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
    "rmagatti/auto-session",
  },
  config = function()
    require("telescope").load_extension "file_browser"
    require("telescope").load_extension "reprosjession"
    require("auto-session").setup {
      cwd_change_handling = {
        restore_upcoming_session = true,
      },
    }
  end,
}
