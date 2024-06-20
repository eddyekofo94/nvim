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
    "mbbill/undotree",
    event = "VeryLazy",
  },
  {
    --  INFO: 2024-06-18 - find and replace
    "MagicDuck/grug-far.nvim",
    config = function()
      require("grug-far").setup {}
    end,
  },

  {
    --  DISABLED: 2024-06-18
    "nvim-pack/nvim-spectre",
    enabled = false,
    event = "VeryLazy",
    config = function()
      local spectre = require "spectre"
      vim.keymap.set(
        "n",
        "<leader>S",
        -- spectre.toggle,
        '<cmd>lua require("spectre").toggle()<CR>',
        {
          desc = "Toggle Spectre",
        }
      )
      vim.keymap.set(
        "n",
        "<leader>sW",
        -- spectre.open_visual { select_word = true },
        '<cmd>lua require("spectre").open_visual({select_word=true})<CR>',
        {
          desc = "Search current word",
        }
      )
      vim.keymap.set("v", "<leader>sW", '<esc><cmd>lua require("spectre").open_visual()<CR>', {
        desc = "Search current word",
      })
      vim.keymap.set(
        "n",
        "<leader>sM",
        -- spectre.open_file_search { select_word = true },
        '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>',
        {
          desc = "Search on current file",
        }
      )
      -- vim.keymap.set("n", "<D-S-r>", spectre.toggle, {
      --   desc = "Toggle Spectre",
      -- })
      -- vim.keymap.set("v", "<D-S-r>", spectre.open_visual, {
      --   desc = "Toggle Spectre",
      -- })
    end,
  },
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
          if stat and stat.type == "directory" then
            vim.api.nvim_del_autocmd(info.id)
            require "oil"
            vim.cmd.edit {
              bang = true,
              mods = { keepjumps = true },
            }
            return true
          end
        end,
      })
    end,
    config = function()
      require "modules.configs.oil"
    end,
  },
}
