return {
  {
    "willothy/flatten.nvim",
    event = "BufReadPre",
    priority = 1001,
    config = function()
      require "modules.configs.flatten"
    end,
  },

  {
    "olimorris/persisted.nvim",
    lazy = false,
    enabled = false,
    config = function()
      require "modules.configs.persisted"
    end,
  },
  -- {
  --   "lewis6991/gitsigns.nvim",
  --   event = "BufReadPre",
  --   dependencies = "nvim-lua/plenary.nvim",
  --   config = function()
  --     require "configs.gitsigns"
  --   end,
  -- },

  -- {
  --   "tpope/vim-fugitive",
  --   cmd = {
  --     "G",
  --     "Gcd",
  --     "Gclog",
  --     "Gdiffsplit",
  --     "Gdrop",
  --     "Gedit",
  --     "Ggrep",
  --     "Git",
  --     "Glcd",
  --     "Glgrep",
  --     "Gllog",
  --     "Gpedit",
  --     "Gread",
  --     "Gsplit",
  --     "Gtabedit",
  --     "Gvdiffsplit",
  --     "Gvsplit",
  --     "Gwq",
  --     "Gwrite",
  --   },
  --   event = { "BufWritePost", "BufReadPre" },
  --   config = function()
  --     require "configs.vim-fugitive"
  --   end,
  -- },

  -- {
  --   "akinsho/git-conflict.nvim",
  --   event = "BufReadPre",
  --   config = function()
  --     require "configs.git-conflict"
  --   end,
  -- },

  -- {
  --   "NvChad/nvim-colorizer.lua",
  --   enabled = not vim.g.retro_sym,
  --   event = { "BufNew", "BufRead" },
  --   config = function()
  --     require "configs.nvim-colorizer"
  --   end,
  -- },
  {
    "rachartier/tiny-devicons-auto-colors.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    event = "VeryLazy",
    config = function()
      require("tiny-devicons-auto-colors").setup()
    end,
  },
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = {
      {
        "-",
        function()
          require("oil").open()
        end,
        { desc = "Open parent directory" },
      },
    },
    init = function() -- Load oil on startup only when editing a directory
      vim.g.loaded_fzf_file_explorer = 1
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      vim.api.nvim_create_autocmd("BufWinEnter", {
        nested = true,
        callback = function(info)
          local path = info.file
          if path == "" then
            return
          end
          local stat = vim.uv.fs_stat(path)
          -- if stat and stat.type == "directory" then
          --   vim.api.nvim_del_autocmd(info.id)
          --   require "oil"
          --   vim.cmd.edit {
          --     bang = true,
          --     mods = { keepjumps = true },
          --   }
          --   return true
          -- end
        end,
      })
    end,
    config = function()
      require "modules.configs.oil"
    end,
  },
}
