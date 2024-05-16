return {
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-treesitter/nvim-treesitter" },
    },
    event = "VeryLazy",
    config = function()
      require("refactoring").setup {}
    end,
  },
  {
    -- Automatically fill/change/remove xml-like tags
    "windwp/nvim-ts-autotag",
    opts = {},
  },
  {
    "danymat/neogen",
    event = "VeryLazy",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = true,
  },
  {
    "gbprod/yanky.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "<c-p>", "<Plug>(YankyPreviousEntry)" },
      { "<c-n>", "<Plug>(YankyNextEntry)" },

      { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" } },
      { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" } },

      {
        "<leader>sY",
        "<cmd>Telescope yank_history theme=ivy<cr>",
        desc = "[Y]ank History",
        mode = { "i", "n", "x" },
      },
    },
  },
}
