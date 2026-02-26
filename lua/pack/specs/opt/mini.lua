---@type pack.spec
return {
  src = 'https://github.com/echasnovski/mini.nvim',
  data = {
    event = 'VeryLazy',
    postload = function()
      require('mini.trailspace').setup()
    end,
  },
}
