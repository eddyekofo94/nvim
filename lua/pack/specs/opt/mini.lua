---@type pack.spec
return {
  src = 'https://github.com/echasnovski/mini.nvim',
  data = {
    postload = function()
      require('mini.trailspace').setup()
    end,
  },
}
