---@type pack.spec
return {
  src = 'https://github.com/simonmclean/triptych.nvim',
  data = {
    cmd = 'Triptych',
    enabled = true,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    postload = function()
      local lmap = require('utils.key').lmap

      lmap('e', '<cmd>Triptych<CR>', '[Triptych] File explorer')

      require('triptych').setup {
        mappings = {
          nav_left = { 'h', '-' },
          quit = { 'q', '<esc>' },
        },
        highlights = {
          file_names = 'NONE',
          directory_names = 'NONE',
        },
        extension_mappings = {
          ['<c-.>'] = {
            mode = 'n',
            fn = function(target)
              require('fzf-lua').files {
                cwd = target.path,
              }
            end,
          },
          ['<c-/>'] = {
            mode = 'n',
            fn = function(target)
              require('fzf-lua').live_grep {
                cwd = target.path,
              }
            end,
          },
        },
      }
    end,
  },
}
