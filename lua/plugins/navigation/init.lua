return {
  {
    "beauwilliams/focus.nvim",
    enabled = true,
    event = "VimEnter",
    cmd = {
      "FocusAutoresize",
    },
    config = function()
      require "plugins.configs.focus"
    end,
  },

  {
    "simonmclean/triptych.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "nvim-tree/nvim-web-devicons", -- optional
    },
    keys = {
      { "<leader>-", "<cmd>Triptych<CR>", desc = "File explorere [Triptych]" },
    },
    config = function()
      require "plugins.configs.triptych"
    end,
  },
}
