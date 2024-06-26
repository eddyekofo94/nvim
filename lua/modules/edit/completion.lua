return {
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      table.insert(opts.sources, {
        name = "lazydev",
        group_index = 0, -- set group index to 0 to skip loading LuaLS completions
      })
    end,
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
      { "hrsh7th/cmp-nvim-lsp-document-symbol" },
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
        config = function(_, opts)
          require("lspkind").init(opts)
        end,
      },
    },
    config = function()
      require "modules.configs.cmp"
    end,
  },
}
