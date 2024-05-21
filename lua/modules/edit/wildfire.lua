return {
  "sustech-data/wildfire.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("wildfire").setup {
      filetype_exclude = {
        "PlenaryTestPopup",
        "TelescopePrompt",
        "chatgpt",
        "checkhealth",
        "dap-repl",
        "help",
        "lspinfo",
        "man",
        "neotest-output",
        "neotest-output-panel",
        "neotest-summary",
        "nnn",
        "notify",
        "qf",
        "spectre_panel",
        "startuptime",
        "tsplayground",
      },
    }
  end,
}
