return {
  {
    "lewis6991/gitsigns.nvim",
    enabled = true,
    event = "BufReadPre",
    dependencies = "nvim-lua/plenary.nvim",
    opts = function()
      return require "plugins.git.gitsigns"
    end,
    config = function(_, opts)
      require("gitsigns").setup(opts)
    end,
  },
  {
    "akinsho/git-conflict.nvim",
    event = "BufReadPre",
    cmd = "GitConflictRefresh",
    config = function()
      require "plugins.git.git-conflict"
    end,
  },
  {
    "sindrets/diffview.nvim",
    opts = {
      use_icons = false,
      enhanced_diff_hl = true,
      default_args = {
        DiffviewOpen = { "--untracked-files=no" },
        DiffviewFileHistory = { "--base=LOCAL" },
      },
    },
    cmd = {
      "DiffviewFileHistory",
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
    },
    dependencies = "nvim-lua/plenary.nvim",
    config = function()
      require("diffview").setup()
    end,
  },
  {
    "kdheepak/lazygit.nvim",
    enabled = true,
    keys = {
      {
        "<leader>G",
        function()
          return vim.cmd [[LazyGit]]
        end,
        desc = "LazyGit",
      },
    },
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
  {
    "NeogitOrg/neogit",
    branch = "nightly",
    event = "VeryLazy",
    cmd = "Neogit",
    dependencies = {
      "sindrets/diffview.nvim",
    },
    config = function()
      require "plugins.git.neogit"
    end,
  },
  {
    "ThePrimeagen/git-worktree.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require "plugins.git.git-worktree"
    end,
  },
  {
    "FabijanZulj/blame.nvim",
    event = "VeryLazy",
    keys = {
      {
        "<leader>gB",
        "<cmd>ToggleBlame virtual<CR>",
        "Git blame side",
      },
    },
  },
}
