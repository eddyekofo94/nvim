return {
  { -- Collection of various small independent plugins/modules
    "echasnovski/mini.nvim",
    config = function()
      require("mini.bufremove").setup()

      require("mini.trailspace").setup()

      -- require("mini.comment").setup()

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },

  {
    "echasnovski/mini.comment",
    event = "VeryLazy",
    opts = {},
  },

  {
    -- Examples:
    --  - va)  - [V]isually select [A]round []paren
    --  - yinq - [Y]ank [I]nside [N]ext [']quote
    --  - ci'  - [C]hange [I]nside [']quote
    "echasnovski/mini.ai",
    event = "BufReadPre",
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    init = function()
      -- no need to load the plugin, since we only need its queries
      require("lazy.core.loader").disable_rtp_plugin "nvim-treesitter-textobjects"
    end,
    config = function()
      local ai = require "mini.ai"
      ai.setup {
        n_lines = 500,
        custom_textobjects = {
          b = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer", "@function.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner", "@function.inner" },
          }, {}),
          c = ai.gen_spec.treesitter({
            a = "@class.outer",
            i = "@class.inner",
          }, {}),
        },
      }
    end,
  },
  {
    "echasnovski/mini.align",
    event = "BufReadPre",
    config = function()
      local align = require "mini.align"
      align.setup {
        modifiers = {
          ["{"] = function(steps, opts)
            opts.split_pattern = "{"
            opts.merge_delimiter = " "
            table.insert(steps.pre_justify, align.gen_step.trim())
          end,
        },
      }
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
