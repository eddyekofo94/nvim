---@type pack.spec
return {
  src = 'https://github.com/folke/todo-comments.nvim',
  data = {
    event = { 'BufReadPre', 'BufNewFile' },
    postload = function()
      require('todo-comments').setup({
        keywords = {
          FIX = {
            icon = ' ',
            color = 'error',
            alt = { 'FIXME', 'BREAK', 'BUG', 'FIXIT', 'ISSUE', 'ERROR' },
          },
          TODO = { icon = ' ', color = 'info' },
          HACK = { icon = ' ', color = 'warning' },
          WARN = { icon = ' ', color = 'warning', alt = { 'WARNING', 'XXX' } },
          PERF = {
            icon = ' ',
            alt = { 'REFACTOR', 'REFC', 'OPTIM', 'PERFORMANCE', 'OPTIMIZE' },
          },
          NOTE = { icon = ' ', color = 'hint', alt = { 'INFO', 'REVIEW' } },
          EXAMPLE = { icon = '󰄛 ', color = 'hint', alt = { 'E.G.' } },
          CLEAN_UP = { icon = ' ', color = 'error', alt = { 'CLEAN', 'DISABLED' } },
          DEBUG = { icon = ' ', color = 'error' },
          TEST = {
            icon = '󰙨 ',
            color = 'test',
            alt = { 'TESTING', 'PASSED', 'FAILED' },
          },
        },
      })

      local map = require('utils.key').map
      map('n', '<leader>Tq', '<cmd>TodoQuickFix<cr>', { desc = 'Search TODO' })
      map('n', ']t', function()
        require('todo-comments').jump_next()
      end, { desc = 'Next todo comment' })
      map('n', '[t', function()
        require('todo-comments').jump_prev()
      end, { desc = 'Previous todo comment' })
    end,
  },
}
