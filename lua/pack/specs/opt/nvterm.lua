---@type pack.spec
return {
  src = 'https://github.com/NvChad/nvterm',
  data = {
    enabled = true,
    event = 'VeryLazy',
    dependencies = { 'MunifTanjim/nui.nvim' },
    postload = function()
      require('nvterm').setup({
        terminals = {
          type_opts = {
            float = {
              relative = 'editor',
              row = 0.3,
              col = 0.25,
              width = 0.5,
              height = 0.4,
              border = 'single',
            },
          },
        },
        behavior = {
          autoclose_on_exit = true,
          auto_insert = true,
        },
      })

      local nmap = require('utils.key').nmap
      local map = require('utils.key').map

      map({ 't', 'n' }, '<A-i>', function()
        return require('nvterm.terminal').toggle('float')
      end, { desc = 'Toggle floating term' })

      map({ 't', 'n' }, '<A-o>', function()
        return require('nvterm.terminal').toggle('horizontal')
      end, { desc = 'Toggle horizontal term' })

      -- map({ 't', 'n' }, '<A-v>', function()
      --   return require('nvterm.terminal').toggle('vertical')
      -- end, { desc = 'Toggle vertical term' })

      nmap('<leader>tf', function()
        return require('nvterm.terminal').new('float')
      end, { desc = 'Terminal new float term' })

      nmap('<leader>tv', function()
        return require('nvterm.terminal').new('vertical')
      end, { desc = 'Terminal new ver term' })
    end,
  },
}
