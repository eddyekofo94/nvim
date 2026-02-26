---@type pack.spec
return {
  src = 'https://github.com/folke/flash.nvim',
  data = {
    events = 'VeryLazy',
    enabled = true,
    keys = {
      { lhs = 'ss', mode = { 'n', 'x', 'o' }, opts = { desc = 'Flash' } },
      -- {
      --   lhs = 'S',
      --   mode = { 'n', 'x', 'o' },
      --   opts = { desc = 'Flash Treesitter' },
      -- },
      {
        lhs = 'r',
        function()
          require('flash').remote()
        end,
        mode = 'o',
        opts = { desc = 'Flash Remote' },
      },
      {
        lhs = 'R',
        mode = { 'o', 'x' },
        opts = { desc = 'Flash Treesitter Search' },
      },
    },
    postload = function()
      local map = require('utils.key').nmap

      require('flash').setup({
        search = {
          forward = true,
          multi_window = false,
          prompt = '> ',
        },
        highlight = {
          matches = false,
        },
        modes = {
          char = {
            enabled = true,
            highlight = {
              backdrop = false,
              matches = true,
            },
            keys = {
              [';'] = 'right',
              [','] = 'left',
            },
          },
        },
      })

      map('ss', function()
        require('flash').jump()
      end, 'Flash jump')

      map('st', function()
        require('flash').treesitter()
      end, 'Flash treesitter')
    end,
  },
}
