return {
  { import = "modules.theme.catppuccin" },
  {
    "f-person/auto-dark-mode.nvim",
    enabled = false,
    lazy = false,
    config = function()
      require("auto-dark-mode").setup {
        update_interval = 1000,
        set_dark_mode = function()
          vim.g.nvchad_theme = "gruvbox"
          vim.g.transparency = false
          require("nvchad.utils").replace_word('theme = "gruvbox_light"', 'theme = "gruvbox"')
        end,
        set_light_mode = function()
          vim.g.nvchad_theme = "gruvbox_light"
          require("nvchad.utils").replace_word('theme = "gruvbox"', 'theme = "gruvbox_light"')
          vim.g.transparency = true
        end,
      }
    end,
  },
  {
    -- log highlight colours
    "MTDL9/vim-log-highlighting",
    event = "VeryLazy",
    ft = "log",
  },
  {
    "dgox16/oldworld.nvim",
    enabled = false,
    lazy = false,
    priority = 1000,
    init = function()
      vim.cmd.colorscheme "oldworld"
    end,
    config = true,
  },
  { -- You can easily change to a different colorscheme.
    -- Change the name of the colorscheme plugin below, and then
    -- change the command in the config to whatever the name of that colorscheme is.
    --
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
    "folke/tokyonight.nvim",
    priority = 1000, -- Make sure to load this before all the other start plugins.
    enabled = false,
    init = function()
      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      vim.cmd.colorscheme "tokyonight-night"

      -- You can configure highlights by doing something like:
      vim.cmd.hi "Comment gui=none"
    end,
  },
  {
    "mcchrish/zenbones.nvim",
    -- Optionally install Lush. Allows for more configuration or extending the colorscheme
    -- If you don't want to install lush, make sure to set g:zenbones_compat = 1
    -- In Vim, compat mode is turned on as Lush only works in Neovim.
    dependencies = "rktjmp/lush.nvim",
    lazy = false,
    config = function()
      -- vim.cmd('colorscheme zenbones')
    end,
  },
  {
    "Verf/deepwhite.nvim",
    lazy = true,
    priority = 1000,
    config = function()
      -- vim.cmd [[colorscheme deepwhite]]
    end,
  },
  {
    "rose-pine/neovim",
    enabled = false,
    config = function()
      require("rose-pine").setup {
        --- @usage 'auto'|'main'|'moon'|'dawn'
        variant = "moon",
        --- @usage 'main'|'moon'|'dawn'
        dark_variant = "main",
        disable_italics = true,
        -- vim.cmd('colorscheme rose-pine'),
      }
    end,
  },
  {
    "rebelot/kanagawa.nvim",
    enabled = false,
    opts = {
      compile = false, -- enable compiling the colorscheme
      undercurl = true, -- enable undercurls
      commentStyle = { italic = false },
      functionStyle = { italic = false },
      keywordStyle = { italic = false },
      statementStyle = { italic = false },
      typeStyle = { italic = false },
      variableStyle = { italic = false },
      transparent = false, -- do not set background color
      dimInactive = false, -- dim inactive window `:h hl-NormalNC`
      terminalColors = true, -- define vim.g.terminal_color_{0,17}
      colors = { -- add/modify theme and palette colors
        palette = {},
        theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
      },
      theme = "dragon", -- Load "wave" theme when 'background' option is not set
      background = { -- map the value of 'background' option to a theme
        dark = "wave", -- try "dragon" !
        light = "lotus",
      },
    },
    config = function()
      vim.cmd [[colorscheme kanagawa]]
    end,
  },
  {
    "olivercederborg/poimandres.nvim",
    enabled = false,
    lazy = false,
    priority = 1000,
    config = function()
      require("poimandres").setup {
        -- leave this setup function empty for default config
        -- or refer to the configuration section
        -- for configuration options
      }
    end,

    -- optionally set the colorscheme within lazy config
    init = function()
      vim.cmd "colorscheme poimandres"
    end,
  },
  {
    "sam4llis/nvim-tundra",
    enabled = false,
    priority = 1000,
    config = function()
      require("nvim-tundra").setup {
        plugins = {
          telescope = true,
          cmp = true,
        },
      }
      vim.g.tundra_biome = "arctic" -- 'arctic' or 'jungle'
      vim.opt.background = "dark"
      vim.cmd "colorscheme tundra"
    end,
  },
  { "EdenEast/nightfox.nvim" },
  { "sainnhe/everforest" },
  { "sainnhe/gruvbox-material" },
  { "sainnhe/edge" },
  { "projekt0n/github-nvim-theme" },
}
