local M = {}

local utils_keymaps = require "utils.keymaps"
-- local map = utils_keymaps.set_keymap
local lmap = utils_keymaps.set_leader_keymap
local small_dot = " "

-- disable semanticTokens
M.on_init = function(client, _)
  if client.supports_method "textDocument/semanticTokens" then
    client.server_capabilities.semanticTokensProvider = nil
  end
end

-- export on_attach & capabilities
M.on_attach = function(client, bufnr)
  local filetype = vim.api.nvim_buf_get_name(bufnr)
  -- local navic = require "nvim-navic"
  -- Enable rounded borders in :LspInfo window.
  require("lspconfig.ui.windows").default_options.border = "rounded"

  local function opts(desc)
    return { buffer = bufnr, desc = desc }
  end
  -- NOTE: Remember that Lua is a real programming language, and as such it is possible
  -- to define small helper and utility functions so you don't have to repeat yourself.
  --
  -- In this case, we create a function that lets us more easily define mappings specific
  -- for LSP related items. It sets the mode, buffer and description for us each time.
  local map = function(keys, func, desc)
    -- vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
    local map = require("utils.keymaps").set_n_keymap
    map(keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
  end

  -- Jump to the definition of the word under your cursor.
  --  This is where a variable was first declared, or where a function is defined, etc.
  --  To jump back, press <C-t>.
  map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

  -- Find references for the word under your cursor.
  map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

  -- Jump to the implementation of the word under your cursor.
  --  Useful when your language has ways of declaring types without an actual implementation.
  map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

  -- Jump to the type of the word under your cursor.
  --  Useful when you're not sure what type a variable is and you want to see
  --  the definition of its *type*, not where it was *defined*.
  map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

  -- Fuzzy find all the symbols in your current document.
  --  Symbols are things like variables, functions, types, etc.
  map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

  -- Fuzzy find all the symbols in your current workspace.
  --  Similar to document symbols, except searches over your entire project.
  map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

  -- Rename the variable under your cursor.
  --  Most Language Servers support renaming across files, etc.
  map("<leader>lr", vim.lsp.buf.rename, "[Lsp] [r]ename")

  -- Execute a code action, usually your cursor needs to be on top of an error
  -- or a suggestion from your LSP for this to activate.
  map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

  -- Opens a popup that displays documentation about the word under your cursor
  --  See `:help K` for why this keymap.
  map("K", vim.lsp.buf.hover, "Hover Documentation")

  -- WARN: This is not Goto Definition, this is Goto Declaration.
  --  For example, in C this would take you to the header.
  map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

  --  INFO: Glance
  lmap("ld", "<cmd>Glance definitions<cr>", opts "Definitions")
  lmap("lD", "<cmd>Glance type_definitions<cr>", opts "Type definitions")
  lmap("li", "<cmd>Glance implementations<cr>", opts "Implementations")
  lmap("lR", "<cmd>Glance references<cr>", opts "References")

  if filetype == "cpp" then
    vim.api.nvim_buf_set_keymap(0, "n", "<s-f>", "<cmd>ClangdSwitchSourceHeader<CR>", { noremap = true, silent = true })
  end
  -- The following two autocommands are used to highlight references of the
  -- word under your cursor when your cursor rests there for a little while.
  --    See `:help CursorHold` for information about when this is executed
  --
  -- When you move your cursor, the highlights will be cleared (the second autocommand).
  -- local client = vim.lsp.get_client_by_id(event.data.client_id)

  -- if client and client.server_capabilities.documentSymbolProvider then
  --   navic.attach(client, bufnr)
  -- end

  if client and client.server_capabilities.documentHighlightProvider then
    local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      buffer = bufnr,
      group = highlight_augroup,
      callback = vim.lsp.buf.document_highlight,
    })

    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      buffer = bufnr,
      group = highlight_augroup,
      callback = vim.lsp.buf.clear_references,
    })

    vim.api.nvim_create_autocmd("LspDetach", {
      group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
      callback = function(event2)
        vim.lsp.buf.clear_references()
        vim.api.nvim_clear_autocmds { group = "kickstart-lsp-highlight", buffer = event2.buf }
      end,
    })
  end

  -- The following autocommand is used to enable inlay hints in your
  -- code, if the language server you are using supports them
  --
  -- This may be unwanted, since they displace some of your code
  if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
    map("<leader>hi", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end, "[T]oggle Inlay [H]ints")
  end

  -- if client and client.supports_method "textDocument/codeLens" then
  --   vim.lsp.codelens.refresh()
  --   --- autocmd BufEnter,CursorHold,InsertLeave <buffer> lua vim.lsp.codelens.refresh()
  --   vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
  --     buffer = bufnr,
  --     callback = vim.lsp.codelens.refresh,
  --   })
  -- end

  vim.cmd.highlight "DiagnosticUnderlineError gui=undercurl" -- use undercurl for error, if supported by terminal
  vim.cmd.highlight "DiagnosticUnderlineWarn  gui=undercurl" -- use undercurl for warning, if supported by terminal

  vim.diagnostic.config {
    virtual_text = {
      spacing = 4,
      source = "if_many",
      prefix = "●",
    },
    severity_sort = true,
    float = {
      show_header = false,
      close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
      scope = "cursor",
      source = "if_many",
      border = "single",
      focusable = false,
    },
    inlay_hints = {
      enabled = true,
    },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = small_dot,
        [vim.diagnostic.severity.WARN] = small_dot,
        [vim.diagnostic.severity.INFO] = small_dot,
        [vim.diagnostic.severity.HINT] = small_dot,
      },
      linehl = {
        [vim.diagnostic.severity.ERROR] = "ErrorMsg",
      },
      numhl = {
        [vim.diagnostic.severity.WARN] = "WarningMsg",
      },
    },
  }
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
M.capabilities.textDocument.completion.completionItem.resolveSupport = { properties = { "documentation", "detail", "additionalTextEdits" } }
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
  require("lspconfig").lua_ls.setup {

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
              [vim.fn.expand "$VIMRUNTIME/lua"] = true,
              [vim.fn.expand "$VIMRUNTIME/lua/vim/lsp"] = true,
              [vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy"] = true,
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
  }
end

return M
