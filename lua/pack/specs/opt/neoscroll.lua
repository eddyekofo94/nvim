---@type pack.spec
return {
  src = 'https://github.com/karb94/neoscroll.nvim',
  data = {
    events = { event = 'FileType' },
    enabled = true,
    postload = function()
      require('neoscroll').setup()
    end,
  },
}
