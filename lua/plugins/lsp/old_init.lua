return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("utils.lsp.lspconfig").defaults()
    -- require "plugins.lsp.lspconfig"
    require "plugins.lsp.init"
  end,
  dependencies = {
    {
      "deathbeam/lspecho.nvim",
      enabled = false,
      config = function()
        require("lspecho").setup { echo = false, decay = 2000 }
      end,
    },
    {
      "linrongbin16/lsp-progress.nvim",
      enabled = false,
      clonfig = function()
        require "configs.lsp.lsp-progress-extra"
      end,
    },
    {
      "SmiteshP/nvim-navbuddy",
      dependencies = {
        "SmiteshP/nvim-navic",
        "MunifTanjim/nui.nvim",
      },
      keys = {
        {
          "<leader>nn",
          "<cmd>Navbuddy<CR>",
          desc = "Navbuddy open",
        },
      },
      opts = { lsp = { auto_attach = true } },
      config = function()
        require "plugins.lsp.navbuddy"
      end,
    },
    {
      --  INFO: 2023-10-19 - this temporarily disables lsp to save the
      --  CPU usage...
      "hinell/lsp-timeout.nvim",
      enabled = true,
      init = function()
        vim.g.lspTimeoutConfig = {
          stopTimeout = 1000 * 60 * 5, -- ms, timeout before stopping all LSP servers
          startTimeout = 1000 * 10, -- ms, timeout before restart
          silent = false, -- true to suppress notifications
        }
      end,
    },
    {
      "dnlhc/glance.nvim",
      event = "LspAttach",
      config = function()
        require("glance").setup {}
      end,
    },
  },
}
