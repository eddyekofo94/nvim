---@type pack.spec
return {
  src = 'https://github.com/Bekaboo/dropbar.nvim',
  enabled = true,
  lazy = false,
  postload = function()
    require('dropbar').setup({
      bar = {
        enable = function(buf, win, _)
          buf = vim._resolve_bufnr(buf)
          if
            not vim.api.nvim_buf_is_valid(buf)
            or not vim.api.nvim_win_is_valid(win)
          then
            return false
          end

          if vim.bo[buf].ft == 'fzf' then
            return false
          end

          if
            not vim.api.nvim_buf_is_valid(buf)
            or not vim.api.nvim_win_is_valid(win)
            or vim.fn.win_gettype(win) ~= ''
            or vim.wo[win].winbar ~= ''
            or vim.wo[win].winbar_no_attach
            or vim.b[buf].winbar_no_attach
            or vim.bo[buf].ft == 'help'
          then
            return false
          end

          local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
          if stat and stat.size > 1024 * 1024 then
            return false
          end

          return vim.bo[buf].bt == 'terminal'
            or vim.bo[buf].ft == 'markdown'
            or pcall(vim.treesitter.get_parser, buf)
            or not vim.tbl_isempty(vim.lsp.get_clients({
              bufnr = buf,
              method = 'textDocument/documentSymbol',
            }))
        end,
      },
    })
    vim.keymap.set('n', '<leader>ls', require('dropbar.api').pick, { desc = '[s]ymbols' })
    vim.api.nvim_create_autocmd({ 'FileType' }, {
      pattern = 'fzf',
      callback = function(args)
        vim.schedule(function()
          for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
            vim.wo[win].winbar = ''
            vim.w[win].winbar_no_attach = true
          end
        end)
      end,
    })

    _G.dropbar = setmetatable({}, {
      __index = function(_, key)
        local ok, mod = pcall(require, 'dropbar')
        if ok and mod then
          return mod[key]
        end
        return function() end
      end,
    })
  end,
}
