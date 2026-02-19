---@type pack.spec
return {
  src = 'https://github.com/max397574/better-escape.nvim',
  data = {
    events = { event = 'InsertEnter' },
    postload = function()
      require('better_escape').setup {
        timeout = 300,
        mappings = {
          i = {
            j = {
              k = '',
              j = '<Esc>',
            },
          },
          t = {
            j = {
              k = {},
            },
          },
        },
      }
    end,
  },
}
