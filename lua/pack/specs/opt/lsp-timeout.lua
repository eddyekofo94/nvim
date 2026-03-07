---@type pack.spec
return {
  src = 'https://github.com/hinell/lsp-timeout.nvim',
  data = {
    event = 'LspAttach',
    dependencies = { 'neovim/nvim-lspconfig' },
    postload = function()
      local ok, lspconfig = pcall(require, 'lspconfig')
      if not ok then
        return
      end
      require('lsp-timeout').setup({
        timeout = 3000,
        notify = true,
      })
    end,
  },
}
