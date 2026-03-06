---@type pack.spec
return {
  src = 'https://github.com/fei6409/log-highlight.nvim',
  data = {
    ft = 'log',
    postload = function()
      require('log-highlight').setup({})
      vim.api.nvim_create_autocmd({ 'BufEnter' }, {
        pattern = { '*.log', '' },
        callback = function()
          vim.diagnostic.enable(false)
        end,
      })
    end,
  },
}
