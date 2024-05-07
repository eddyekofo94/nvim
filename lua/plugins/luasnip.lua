return {
  "L3MON4D3/LuaSnip",
  event = "InsertEnter",
  dependencies = {
    "rafamadriz/friendly-snippets",
  },
  build = "make install_jsregexp",
  config = function()
    require("plugins.configs.luasnip")
  end,
}
