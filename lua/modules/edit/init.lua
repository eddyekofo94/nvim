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
    "nguyenvukhang/nvim-toggler",
    keys = {
      { "<leader>ii", desc = "Toggle Word" },
    },
    config = function()
      require("nvim-toggler").setup {
        remove_default_keybinds = true,
      }
      vim.keymap.set({ "n", "v" }, "<leader>ii", require("nvim-toggler").toggle, { desc = "Toggle a Word" })
    end,
  },
  {
    "altermo/ultimate-autopair.nvim",
    enabled = true,
    branch = "v0.6", --recomended as each new version will have breaking changes
    event = { "InsertEnter", "CmdlineEnter" },
    config = function()
      require "modules.configs.ultimate-autopair"
    end,
  },
  {
    "chrisgrieser/nvim-spider",
    opts = {
      skipInsignificantPunctuation = true,
    },
    event = "VeryLazy",
    keys = { "w", "e", "b", "ge" },
    config = function()
      require "modules.configs.spider"
    end,
  },
  {
    "danymat/neogen",
    event = "VeryLazy",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = true,
  },
}
