---@type pack.spec
return {
  src = 'https://github.com/dnlhc/glance.nvim',
  data = {
    event = 'LspAttach',
    postload = function()
      require('glance').setup({})
    end,
  },
}
