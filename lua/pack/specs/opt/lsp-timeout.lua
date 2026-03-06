---@type pack.spec
return {
  src = 'https://github.com/hinell/lsp-timeout.nvim',
  data = {
    event = 'LspAttach',
    postload = function()
      require('lsp-timeout').setup({
        timeout = 3000,
        notify = false,
      })
    end,
  },
}
