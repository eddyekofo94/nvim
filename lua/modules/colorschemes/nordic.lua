return {
  "AlexvZyl/nordic.nvim",
  lazy = false,
  enabled = false,
  priority = 1000,
  config = function()
    vim.cmd.colorscheme "nordic"
    require("nordic").load()
  end,
}
