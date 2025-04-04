return {
  --  LSP -------------------------------------------------------------------

  -- nvim-java [java support]
  -- https://github.com/nvim-java/nvim-java
  -- Reliable jdtls support. Must go before mason-lspconfig and lsp-config.
  {
    "nvim-java/nvim-java",
    enabled = true,
    ft = { "java" },
    dependencies = {
      "MunifTanjim/nui.nvim",
      "neovim/nvim-lspconfig",
      "mfussenegger/nvim-dap",
      "williamboman/mason.nvim",
    },
    opts = {
      notifications = {
        dap = false,
      },
      -- NOTE: One of these files must be in your project root directory.
      --       Otherwise the debugger will end in the wrong directory and fail.
      root_markers = {
        "settings.gradle",
        "settings.gradle.kts",
        "pom.xml",
        "build.gradle",
        "mvnw",
        "gradlew",
        "build.gradle",
        "build.gradle.kts",
        ".git",
      },
    },
  },

  --  nvim-lspconfig [lsp configs]
  --  https://github.com/neovim/nvim-lspconfig
  --  This plugin provide default configs for the lsp servers available on mason.
  {
    "neovim/nvim-lspconfig",
    enabled = false,
    event = "User BaseFile",
    dependencies = "nvim-java/nvim-java",
    config = function()
      return require "configs.lspconfig"
    end,
  },

  --  mason [lsp package manager]
  --  https://github.com/williamboman/mason.nvim
  --  https://github.com/zeioth/mason-extra-cmds
  {
    "williamboman/mason.nvim",
    dependencies = { "zeioth/mason-extra-cmds", opts = {} },
    cmd = {
      "Mason",
      "MasonInstall",
      "MasonUninstall",
      "MasonUninstallAll",
      "MasonLog",
      "MasonUpdate",
      "MasonUpdateAll", -- this cmd is provided by mason-extra-cmds
    },
    opts = {
      registries = {
        "github:nvim-java/mason-registry",
        "github:mason-org/mason-registry",
      },
      ui = {
        icons = {
          -- package_installed = require("base.utils").get_icon "MasonInstalled",
          -- package_uninstalled = require("base.utils").get_icon "MasonUninstalled",
          -- package_pending = require("base.utils").get_icon "MasonPending",
        },
      },
    },
  },
}
