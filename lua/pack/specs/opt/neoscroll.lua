---@type pack.spec
return {
  src = 'https://github.com/karb94/neoscroll.nvim',
  data = {
    events = { event = 'BufReadPre' },
    enabled = true,
    postload = function()
      require('neo-scroll').setup()
    end,
  },
}
