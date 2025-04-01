return {
  { import = "modules.mini" },
  { import = "modules.edit" },
  { import = "modules.navigation" },
  { import = "modules.git" },
  { import = "modules.lsp" },
  { import = "modules.main" },
  { import = "modules.ui" },
  {
    "NvChad/nvterm",
    enabled = true,
    event = "VeryLazy",
    config = function()
      require("nvterm").setup()
      require "modules.configs.nvterm"
    end,
  },
  {
    "folke/noice.nvim",
    enabled = true,
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require "modules.configs.noice"
    end,
  },
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      { "<leader>Tq", "<cmd>TodoQuickFix<cr>", desc = "Search TODO" },
      {
        "]t",
        "<cmd>lua require('todo-comments').jump_next()<cr>",
        { desc = "Next todo comment" },
      },
      {
        "[t",
        "<cmd>lua require('todo-comments').jump_prev()<cr>",
        { desc = "Previous todo comment" },
      },
    },
    opts = require "modules.configs.todo-comments",
  },
  {
    "ThePrimeagen/harpoon",
    enabled = false,
    event = "VeryLazy",
    config = function()
      require "modules.configs.harpoon"
    end,
  },
  {
    "smjonas/live-command.nvim",
    enabled = false,
    event = "CmdlineEnter",
    config = function()
      require("live-command").setup {
        commands = {
          Norm = { cmd = "norm" },
        },
      }
    end,
  },

  {
    -- "ahmedkhalf/project.nvim",
    --  INFO: 2024-06-17 - nvim-telescope/telescope-project.nvim
    -- natecraddock/workspaces.nvim -- look into this?
    "LennyPhoenix/project.nvim", -- Temporary switch to fork
    branch = "fix-get_clients",
    -- can't use 'opts' because module has non standard name 'project_nvim'
    config = function()
      require("project_nvim").setup {
        scope_chdir = "global",
        patterns = {
          ".git",
          "package.json",
          "go.mod",
          "Makefile",
          "pom.xml",
          "requirements.yml",
          "pyrightconfig.json",
          "pyproject.toml",
        },
        detection_methods = { "lsp", "pattern" },
      }
    end,
  },
  {
    "RRethy/vim-illuminate",
    -- INFO: disabled for now
    enabled = false,
    event = "BufWinEnter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    config = require "modules.configs.illuminate",
  },
  {
    "utilyre/sentiment.nvim",
    version = "*",
    enabled = false,
    event = "VeryLazy", -- keep for lazy loading
    opts = {
      -- config
    },
    init = function()
      -- `matchparen.vim` needs to be disabled manually in case of lazy loading
      vim.g.loaded_matchparen = 1
    end,
  },
  {
    "andymass/vim-matchup",
    enabled = true,
    event = "BufReadPre",
    init = function()
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
    end,
  },
  {
    "smoka7/multicursors.nvim",
    enabled = false,
    event = "VeryLazy",
    dependencies = {
      "smoka7/hydra.nvim",
    },
    opts = {},
    cmd = {
      "MCstart",
      "MCvisual",
      "MCclear",
      "MCpattern",
      "MCvisualPattern",
      "MCunderCursor",
    },
    keys = {
      {
        mode = { "v", "n" },
        "<Leader>mc",
        "<cmd>MCstart<cr>",
        desc = "Multi cursor",
      },
    },
  },
  {
    "nacro90/numb.nvim",
    event = "VeryLazy",
    opts = {
      show_numbers = true, -- Enable 'number' for the window while peeking
      show_cursorline = true, -- Enable 'cursorline' for the window while peeking
      hide_relativenumbers = true, -- Enable turning off 'relativenumber' for the window while peeking
      number_only = false, -- Peek only when the command is only a number instead of when it starts with a number
      centered_peeking = true, -- Peeked line will be centered relative to window
    },
  },
  {
    "folke/zen-mode.nvim",
    event = "VeryLazy",
    enabled = false,
    dependencies = {
      {
        "folke/twilight.nvim",
        config = function()
          require("twilight").setup {
            context = -1,
            treesitter = true,
          }
        end,
      },
    },
    config = require "modules.configs.zen",
  },

  {
    "NMAC427/guess-indent.nvim",
    event = "VeryLazy",
    enabled = true,
    config = function()
      require("guess-indent").setup {}
      local guess_indent = require "guess-indent"
      guess_indent.set_from_buffer(_, _, true)
    end,
  },
  {
    "rachartier/tiny-glimmer.nvim",
    event = "VeryLazy",
    opts = {
      -- your configuration
    },
  },
  {
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    -- event = "VeryLazy",
    lazy = false,
    opts = require("modules.configs.ufo").opts,
    init = require("modules.configs.ufo").init(),
    config = function(opts)
      require("modules.configs.ufo").config(opts)
    end,
  },
  {
    "brenoprata10/nvim-highlight-colors",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("nvim-highlight-colors").setup {
        ---Render style
        ---@usage 'background'|'foreground'|'virtual'
        render = "background",
        ---Highlight named colors, e.g. 'green'
        enable_named_colors = false,
      }
    end,
  },
  {
    "arsham/indent-tools.nvim",
    event = "VeryLazy",
    priority = 999,
    dependencies = {
      "arsham/arshlib.nvim",
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = true,
    keys = { "]i", "[i" },
    -- or to provide configuration
    -- config = { normal = {..}, textobj = {..}},
  },
  {
    -- INFO: does this work?
    "ironhouzi/starlite-nvim",
    event = "WinEnter",
    config = function()
      local map = vim.keymap.set
      local default_options = { silent = true }
      map("n", "*", ":lua require'starlite'.star()<cr>", default_options)
      map("n", "g*", ":lua require'starlite'.g_star()<cr>", default_options)
      map("n", "#", ":lua require'starlite'.hash()<cr>", default_options)
      map("n", "g#", ":lua require'starlite'.g_hash()<cr>", default_options)
    end,
  },
  {
    "ten3roberts/qf.nvim",
    enabled = false,
    config = function()
      require("qf").setup {}
    end,
  },
  {
    -- INFO: jj == esc
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup {
        timeout = 300,
        mappings = {
          i = {
            j = {
              -- These can all also be functions
              k = "",
              j = "<Esc>",
            },
          },
          t = {
            j = {
              k = {},
            },
          },
        },
      }
    end,
  },
  {
    "nvim-zh/colorful-winsep.nvim",
    enabled = true,
    branch = "main", -- change to alpha if satisfied with its updates
    event = { "WinNew" },
    opts = require "modules.configs.winsep",
    config = true,
  },
  {
    "chrisgrieser/nvim-early-retirement",
    event = "VeryLazy",
    config = true,
    opts = require "modules.configs.early-retirement",
  },

  {
    "kylechui/nvim-surround",
    enabled = false,
    event = "VeryLazy",
    keys = {
      { "s", mode = { "n", "x", "o" } },
      { "S", mode = "x" },
    },
    config = function()
      require "modules.configs.nvim-surround"
    end,
  },
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      {
        "dreamsofcode-io/nvim-dap-go",
        ft = "go",
        dependencies = "mfussenegger/nvim-dap",
        config = function(_, opts)
          require("dap-go").setup(opts)
        end,
      },
    },
  },
}
