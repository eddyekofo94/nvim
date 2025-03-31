return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    priority = 1000,
    build = ":TSUpdate",
    cmd = {
      "TSBufDisable",
      "TSBufEnable",
      "TSBufToggle",
      "TSDisable",
      "TSEnable",
      "TSToggle",
      "TSInstall",
      "TSInstallInfo",
      "TSInstallSync",
      "TSModuleInfo",
      "TSUninstall",
      "TSUpdate",
      "TSUpdateSync",
    },
    opts = require "modules.configs.treesitter",
    dependencies = {
      {
        "RRethy/nvim-treesitter-endwise",
        event = "FileType",
      },
      {
        "nvim-treesitter/nvim-treesitter-context",
        event = "BufReadPre",
        opts = {
          enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
          max_lines = 4, -- How many lines the window should span. Values <= 0 mean no limit.
          multiline_threshold = 20, -- Maximum number of lines to show for a single context
          trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
          zindex = 20, -- The Z-index of the context window
          mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
          on_attach = function()
            local disabled_filetypes = { "markdown", "vim" }
            -- local ft = vim.bo.ft:gsub("^%l", string.lower)
            local ft = vim.bo.filetype

            return not vim.tbl_contains(disabled_filetypes, ft)
          end,
          patterns = {
            default = {
              "class",
              "function",
              "method",
              "for", -- These won't appear in the context
              "while",
              "if",
              "switch",
              "case",
              "const",
            },
          },
        },
        config = function(_, opts)
          local context = require "treesitter-context"
          context.setup(opts)
        end,
      },
      {
        "JoosepAlviste/nvim-ts-context-commentstring",
        opts = {
          enable_autocmd = false,
        },
      },
    },
    config = function(_, opts)
      vim.treesitter.language.register("bash", "zsh")
      -- Prefer git instead of curl in order to improve connectivity in some environments
      require("nvim-treesitter.install").prefer_git = true
      ---@diagnostic disable-next-line: missing-fields
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    enabled = true,
    lazy = false,
    config = function()
      -- When in diff mode, we want to use the default
      -- vim text objects c & C instead of the treesitter ones.
      local move = require "nvim-treesitter.textobjects.move" ---@type table<string,fun(...)>
      local configs = require "nvim-treesitter.configs"
      for name, fn in pairs(move) do
        if name:find "goto" == 1 then
          move[name] = function(q, ...)
            if vim.wo.diff then
              local config = configs.get_module("textobjects.move")[name] ---@type table<string,string>
              for key, query in pairs(config or {}) do
                if q == query and key:find "[%]%[][cC]" then
                  vim.cmd("normal! " .. key)
                  return
                end
              end
            end
            return fn(q, ...)
          end
        end
      end
    end,
    -- event = "VeryLazy"
    -- config = true,
    -- init = function() end,
  },
}
