---@type pack.spec
return {
  'max397574/better-escape.nvim',
  event = 'InsertEnter',
  config = function()
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
}
