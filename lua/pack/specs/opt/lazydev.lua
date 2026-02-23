---@type pack.spec
return {
  src = 'https://github.com/folke/lazydev.nvim',
  data = {
    ft = 'lua',
    dependencies = { 'Bilal2453/luvit-meta' },
    postload = function()
      require('lazydev').setup({
        library = {
          { path = 'luvit-meta/library', words = { 'vim%.uv' } },
        },
      })
    end,
  },
}
