---@type vim.lsp.Config
return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc" },
  settings = {
    Lua = {
      completion = {
        autoRequire = true,
        callSnippet = "Replace", -- Replace
        displayContext = 5,
        keywordSnippet = "Replace", -- show keyword and snippet in suggestion
      },
      format = {
        enable = true,
        defaultConfig = {
          indent_style = "space",
          indent_size = "2",
          max_line_length = "100",
          trailing_table_separator = "smart",
        },
      },
      hint = {
        enable = true,
        arrayIndex = "enable",
        setType = true,
      },
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = "LuaJIT",
      },
      diagnostics = {
        disable = { "missing-fields", "trailing-space", "duplicate-doc-alias" },
        globals = { "vim", "use", "quarto", "pandoc", "io", "string", "print", "require", "table" },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        workspace = {
          library = {
            { path = "snacks.nvim", words = { "Snacks" } },
            vim.fn.expand "$VIMRUNTIME/lua",
            vim.fn.expand "$VIMRUNTIME/lua/vim/lsp",
            vim.fn.stdpath "data" .. "/lazy/ui/nvchad_types",
            vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy",
            "${3rd}/luv/library",
          },
          maxPreload = 100000,
          preloadFileSize = 10000,
          checkThirdParty = false, -- THIS IS THE IMPORTANT LINE TO ADD
          didChangeWatchedFiles = {
            dynamicRegistration = false,
          },
        },
      },
      telemetry = {
        enable = false,
      },
    },
  },
}
