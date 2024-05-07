return {
  { -- Collection of various small independent plugins/modules
    "echasnovski/mini.nvim",
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round []paren
      --  - yinq - [Y]ank [I]nside [N]ext [']quote
      --  - ci'  - [C]hange [I]nside [']quote
      require("mini.ai").setup { n_lines = 500 }

      require("mini.bufremove").setup()

      require("mini.trailspace").setup()

      require("mini.comment").setup()

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },
  {
    "echasnovski/mini.surround",
    enabled = false,
    event = "BufReadPre",
    opts = {
      search_method = "cover_or_next",
      highlight_duration = 2000,
      mappings = {
        add = "ys",
        delete = "ds",
        replace = "cs",
        highlight = "",
        find = "",
        find_left = "",
        update_n_lines = "",
      },
      custom_surroundings = {
        ["("] = { output = { left = "( ", right = " )" } },
        ["["] = { output = { left = "[ ", right = " ]" } },
        ["{"] = { output = { left = "{ ", right = " }" } },
        ["<"] = { output = { left = "<", right = ">" } },
        ["|"] = { output = { left = "|", right = "|" } },
        ["%"] = { output = { left = "<% ", right = " %>" } },
      },
    },
    config = function(_, opts)
      require("mini.surround").setup(opts)
    end,
  },
  {
    "echasnovski/mini.animate",
    event = "VeryLazy",
    enabled = true,
    version = false,
    config = function()
      local animate = require "mini.animate"
      local timing = animate.gen_timing.linear { duration = 100, unit = "total" }
      animate.setup {
        cursor = {
          timing = animate.gen_timing.linear { duration = 10, unit = "total" },
        },
        resize = {
          enable = false,
          timing = animate.gen_timing.linear { duration = 10, unit = "total" },
        },
        scroll = {
          timing = timing,
        },
        open = { enable = true },
        close = { enable = false },
      }
    end,
  },
}
