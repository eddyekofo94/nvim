local M = {}

-- local conf = require("nvconfig").ui.lsp
local utils_keymaps = require("utils.keymaps")
local map = utils_keymaps.set_keymap
local lmap = utils_keymaps.set_leader_keymap

-- disable semanticTokens
M.on_init = function(client, _)
  if client.supports_method("textDocument/semanticTokens") then
    client.server_capabilities.semanticTokensProvider = nil
  end
end

-- export on_attach & capabilities
M.on_attach = function(client, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = desc }
  end

  map("n", "gD", vim.lsp.buf.declaration, opts("Lsp Go to declaration"))
  map("n", "gd", vim.lsp.buf.definition, opts("Lsp Go to definition"))
  map("n", "K", vim.lsp.buf.hover, opts("Lsp hover information"))
  map("n", "gi", vim.lsp.buf.implementation, opts("Lsp Go to implementation"))
  map("n", "<leader>sh", vim.lsp.buf.signature_help, opts("Lsp Show signature help"))
  map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts("Lsp Add workspace folder"))
  map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts("Lsp Remove workspace folder"))

  map("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts("Lsp List workspace folders"))

  -- map("n", "<leader>D", vim.lsp.buf.type_definition, opts "Lsp Go to type definition")

  --  INFO: 2024-04-24 - Add a RENAMER when done
  -- map("n", "<leader>lr", function()
  --   require("nvchad.lsp.renamer")()
  -- end, opts("Lsp NvRenamer"))

  map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts("Lsp Code action"))
  map("n", "gr", vim.lsp.buf.references, opts("Lsp Show references"))

  --  INFO: Glance
  lmap("ld", "<cmd>Glance definitions<cr>", opts("Definitions"))
  lmap("lD", "<cmd>Glance type_definitions<cr>", opts("Type definitions"))
  lmap("li", "<cmd>Glance implementations<cr>", opts("Implementations"))
  lmap("lR", "<cmd>Glance references<cr>", opts("References"))

  -- setup signature popup
  -- if conf.signature and client.server_capabilities.signatureHelpProvider then
  --   require("nvchad.lsp.signature").setup(client, bufnr)
  -- end
end

M.capabilities = vim.lsp.protocol.make_client_capabilities()
M.capabilities.textDocument.completion.completionItem.documentationFormat = { "markdown", "plaintext" }
M.capabilities.textDocument.completion.completionItem.snippetSupport = true
M.capabilities.textDocument.completion.completionItem.preselectSupport = true
M.capabilities.textDocument.completion.completionItem.insertReplaceSupport = true
M.capabilities.textDocument.completion.completionItem.labelDetailsSupport = true
M.capabilities.textDocument.completion.completionItem.deprecatedSupport = true
M.capabilities.textDocument.completion.completionItem.commitCharactersSupport = true
M.capabilities.textDocument.completion.completionItem.tagSupport = { valueSet = { 1 } }
M.capabilities.textDocument.completion.completionItem.resolveSupport =
  { properties = { "documentation", "detail", "additionalTextEdits" } }
M.capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
-- M.capabilities = require("cmp_nvim_lsp").default_capabilities()

M.capabilities.textDocument.completion.completionItem = {
  documentationFormat = { "markdown", "plaintext" },
  snippetSupport = true,
  preselectSupport = true,
  insertReplaceSupport = true,
  labelDetailsSupport = true,
  deprecatedSupport = true,
  commitCharactersSupport = true,
  tagSupport = { valueSet = { 1 } },
  resolveSupport = {
    properties = {
      "documentation",
      "detail",
      "additionalTextEdits",
    },
  },
}

M.defaults = function()
  require("lspconfig").lua_ls.setup({

    on_init = M.on_init,
    capabilities = M.capabilities,
    settings = {
      Lua = {
        completion = {
          autoRequire = true,
          callSnippet = "Replace",
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
          globals = { "vim", "use" },
        },
        workspace = {
          -- Make the server aware of Neovim runtime files
          workspace = {
            library = {
              [vim.fn.expand("$VIMRUNTIME/lua")] = true,
              [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
              [vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua/lazy"] = true,
            },
            -- library = vim.api.nvim_get_runtime_file("", true),
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
  })
end

return M
