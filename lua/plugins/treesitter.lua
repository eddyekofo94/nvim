return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    {
      "RRethy/nvim-treesitter-endwise",
      event = "FileType",
    },
    { "nvim-treesitter/nvim-treesitter-context", config = true },
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
      -- config = true,
      init = function() end,
    },
  },
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
  build = ":TSUpdate",
  opts = function()
    return require "plugins.configs.treesitter"
  end,
  config = function(_, opts)
    vim.treesitter.language.register("bash", "zsh")
    require("nvim-treesitter.configs").setup(opts)
  end,
}
