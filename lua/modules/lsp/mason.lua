require("mason").setup()
require("mason-lspconfig").setup {
  automatic_installation = true,
  ensure_installed = {
    "lua_ls",
    "vimls",
    "rust_analyzer",
    "yamlls",
    "gopls",
    "pylsp",
    "clangd",
    "bashls",
    "sqlls",
    "cmake",
    "gopls",
    "glint",
    "dockerls",
  },
}
