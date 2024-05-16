return {
  {
    "altermo/ultimate-autopair.nvim",
    enabled = true,
    branch = "v0.6", --recomended as each new version will have breaking changes
    event = { "InsertEnter", "CmdlineEnter" },
    config = function()
      require "plugins.configs.ultimate-autopair"
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      {
        -- INFO: additional snippets
        "mireq/luasnip-snippets",
        enabled = true,
        init = function()
          require("luasnip_snippets.common.snip_utils").setup()
        end,
      },
      { "lukas-reineke/cmp-rg" },
      { "hrsh7th/cmp-buffer" }, -- Optional
      { "hrsh7th/cmp-cmdline" },
      { "ray-x/cmp-treesitter" },
      { "dmitmel/cmp-cmdline-history" },
      { "hrsh7th/cmp-nvim-lsp" },
      { "saadparwaiz1/cmp_luasnip" },
      { "hrsh7th/cmp-nvim-lsp" },
      { "hrsh7th/cmp-path" },
      { "hrsh7th/cmp-nvim-lsp-signature-help" },
      { "petertriho/cmp-git", dependencies = { "nvim-lua/plenary.nvim" } },
      {
        "tzachar/cmp-fuzzy-path",
        dependencies = { "tzachar/fuzzy.nvim" },
      },
      {
        "onsails/lspkind.nvim",
        lazy = true,
        opts = {
          mode = "symbol",
          symbol_map = {
            Array = "󰅪",
            Boolean = "⊨",
            Class = "󰌗",
            Constructor = "",
            Key = "󰌆",
            Namespace = "󰅪",
            Null = "NULL",
            Number = "#",
            Object = "󰀚",
            Package = "󰏗",
            Property = "",
            Reference = "",
            Snippet = "",
            String = "󰀬",
            TypeParameter = "󰊄",
            Unit = "",
          },
          menu = {},
        },
        config = require "plugins.lsp.lspkind",
      },
    },
    config = function()
      require "plugins.configs.cmp"
    end,
  },
  {
    "nguyenvukhang/nvim-toggler",
    keys = {
      { "<leader>ii", desc = "Toggle Word" },
    },
    config = function()
      require("nvim-toggler").setup {
        remove_default_keybinds = true,
      }
      vim.keymap.set({ "n", "v" }, "<leader>ii", require("nvim-toggler").toggle, { desc = "Toggle a Word" })
    end,
  },
}
