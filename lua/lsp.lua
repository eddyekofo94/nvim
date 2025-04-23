local root_patterns = require("utils.fs").root_patterns -- This is where you enable features that only work

local small_dot = " "
local icons = require("utils").static.icons

-- if there is a language server active in the file
vim.api.nvim_create_autocmd("LspAttach", {
  desc = "LSP actions",
  callback = function(event)
    local utils_keymaps = require "utils.keymap.keymaps"
    local lmap = utils_keymaps.set_leader_keymap
    local bufnr = event.buf
    local filetype = vim.api.nvim_buf_get_name(bufnr)

    local function opts(desc)
      return { buffer = bufnr, desc = desc }
    end
    -- vim.keymap.set("n", "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", opts)
    -- vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
    -- vim.keymap.set("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", opts)
    -- vim.keymap.set("n", "go", "<cmd>lua vim.lsp.buf.type_definition()<cr>", opts)
    -- vim.keymap.set("n", "gr", "<cmd>lua vim.lsp.buf.references()<cr>", opts)
    -- vim.keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", opts)
    -- vim.keymap.set("n", "gc", "<cmd>lua vim.lsp.buf.rename()<cr>", opts)
    -- vim.keymap.set({ "n", "x" }, "<F3>", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
    -- vim.keymap.set("n", "<F4>", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)
    local map = function(keys, func, desc)
      -- vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
      local map = require("utils.keymap.keymaps").set_n_keymap
      map(keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
    end

    map("K", vim.lsp.buf.hover, "Hover")
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
      vim.api.nvim_buf_set_keymap(
        0,
        "n",
        "<s-f>",
        "<cmd>ClangdSwitchSourceHeader<CR>",
        { noremap = true, silent = true }
      )
    end
  end,
})

-- This is copied straight from blink
-- https://cmp.saghen.dev/installation#merging-lsp-capabilities
local capabilities = {
  textDocument = {
    foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true,
    },
  },
}

capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

-- Setup language servers.

vim.lsp.config("*", {
  capabilities = capabilities,
  root_markers = root_patterns,
  jump = {
    float = false,
  },
  float = { border = "single" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = vim.trim(icons.Diamond),
      [vim.diagnostic.severity.WARN] = vim.trim(icons.TriangleUp),
      [vim.diagnostic.severity.INFO] = small_dot,
      [vim.diagnostic.severity.HINT] = small_dot,
    },
  },
})

vim.diagnostic.config {
  virtual_text = false,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = icons.Diamond,
      [vim.diagnostic.severity.WARN] = "󰔶 ",
      [vim.diagnostic.severity.INFO] = "󰋼",
      [vim.diagnostic.severity.HINT] = "󰌵",
    },
    linehl = {
      [vim.diagnostic.severity.ERROR] = "ErrorMsg",
    },
    numhl = {
      [vim.diagnostic.severity.WARN] = "WarningMsg",
    },
  },
  float = {
    border = "rounded",
    format = function(d)
      return ("%s (%s) [%s]"):format(d.message, d.source, d.code or d.user_data.lsp.code)
    end,
  },
  underline = true,
  jump = {
    float = true,
  },
}
