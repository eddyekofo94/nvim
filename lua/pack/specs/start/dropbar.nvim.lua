---@type pack.spec
return {
  src = "https://github.com/Bekaboo/dropbar.nvim",
  enabled = true,
  lazy = false,
  postload = function()
    local function is_otter_client(client)
      return client
        and type(client.name) == "string"
        and client.name:match "^otter%-ls"
    end

    local function disable_otter_symbols(client)
      if not is_otter_client(client) then
        return
      end

      if client.server_capabilities then
        client.server_capabilities.documentSymbolProvider = false
      end
    end

    local function has_document_symbol_client(buf)
      for _, client in
        ipairs(vim.lsp.get_clients {
          bufnr = buf,
          method = "textDocument/documentSymbol",
        })
      do
        if not is_otter_client(client) then
          return true
        end
      end

      return false
    end

    for _, client in ipairs(vim.lsp.get_clients()) do
      disable_otter_symbols(client)
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      desc = "Keep dropbar from requesting document symbols from otter buffers.",
      group = vim.api.nvim_create_augroup("dropbar.otter_symbols", {}),
      callback = function(args)
        if not args.data or not args.data.client_id then
          return
        end

        local client = vim.lsp.get_client_by_id(args.data.client_id)
        disable_otter_symbols(client)
      end,
    })

    require("dropbar").setup {
      bar = {
        enable = function(buf, win, _)
          buf = vim._resolve_bufnr(buf)
          if
            not vim.api.nvim_buf_is_valid(buf)
            or not vim.api.nvim_win_is_valid(win)
          then
            return false
          end

          if vim.bo[buf].ft == "fzf" then
            return false
          end

          if
            not vim.api.nvim_buf_is_valid(buf)
            or not vim.api.nvim_win_is_valid(win)
            or vim.fn.win_gettype(win) ~= ""
            or vim.wo[win].winbar ~= ""
            or vim.w[win].winbar_no_attach
            or vim.b[buf].winbar_no_attach
            or vim.bo[buf].ft == "help"
          then
            return false
          end

          local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
          if stat and stat.size > 1024 * 1024 then
            return false
          end

          return vim.bo[buf].bt == "terminal"
            or vim.bo[buf].ft == "markdown"
            or pcall(vim.treesitter.get_parser, buf)
            or has_document_symbol_client(buf)
        end,
      },
    }
    vim.keymap.set(
      "n",
      "<leader>ls",
      require("dropbar.api").pick,
      { desc = "[s]ymbols" }
    )
    vim.api.nvim_create_autocmd({ "FileType" }, {
      pattern = "fzf",
      callback = function(args)
        vim.schedule(function()
          for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
            vim.wo[win].winbar = ""
            vim.w[win].winbar_no_attach = true
          end
        end)
      end,
    })

  end,
}
