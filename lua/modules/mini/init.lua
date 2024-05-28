return {
  { -- Collection of various small independent plugins/modules
    "echasnovski/mini.nvim",
    config = function()
      require("mini.bufremove").setup()

      require("mini.trailspace").setup {}

      require("mini.fuzzy").setup()

      local map = require("utils.keymaps").set_keymap

      -- map("n", "<leader>sn", MiniFuzzy.filtersort(word, candidate_array), opts)
      --  INFO: 2024-05-15 - I already have something set up, maybe remove it and change to
      -- this in the future?

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },

  {
    "echasnovski/mini.comment",
    event = "VeryLazy",
    opts = {
      options = {
        custom_commentstring = function()
          return require("ts_context_commentstring.internal").calculate_commentstring() or vim.bo.commentstring
        end,
      },
    },
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
  -- Split and join arguments
  {
    "echasnovski/mini.splitjoin",
    keys = {
      { "sj", "<cmd>lua MiniSplitjoin.join()<CR>", mode = { "n", "x" }, desc = "Join arguments" },
      { "sk", "<cmd>lua MiniSplitjoin.split()<CR>", mode = { "n", "x" }, desc = "Split arguments" },
    },
    opts = {
      mappings = { toggle = "" },
    },
  },
}
