return {
  {
    "nvchad/ui",
    config = function()
      require "nvchad"
    end,
  },

  {
    "nvchad/base46",
    lazy = true,
    build = function()
      require("base46").load_all_highlights()
    end,
  },

  {
    "nvzone/volt", -- optional, needed for theme switcher
    enabled = true,
    event = "VeryLazy",
    config = function()
      vim.keymap.set("n", "<leader>tn", function()
        return require("nvchad.themes").open()
      end, { desc = "theme picker" })
      -- require("nvchad.themes").open()
    end,
  },
}
