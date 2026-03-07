---@type pack.spec
return {
  src = 'https://github.com/echasnovski/neo-scroll.nvim',
  data = {
    event = 'VimEnter',
    postload = function()
      require('neo-scroll').setup()
    end,
  },
}
