---@type pack.spec
return {
  src = "https://github.com/uhhuhuhuhuh/themeswitcher.nvim",
  data = {
    postload = function()
      require("themeswitcher").setup {
        themes = {
          "onedark",
          "everforest",
          "gruvbox-material",
          "catppuccin",
        },
        make_Color_cmd = true,
      }
      vim.keymap.set("n", "<leader>tn", function()
        require("themeswitcher").open_window()
      end, { desc = "theme picker" })
    end,
  },
}
