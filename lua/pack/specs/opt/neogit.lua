---@type pack.spec
return {
  src = 'https://github.com/NeogitOrg/neogit',
  data = {
    branch = 'master',
    cmd = 'Neogit',
    enabled = true,
    dependencies = {
      'sindrets/diffview.nvim',
      'nvim-lua/plenary.nvim',
    },
    postload = function()
      vim.opt.fillchars = { diff = ' ' }
      local lmap = require('utils.map').lmap

      local neogit = require('neogit')

      neogit.setup({
        commit_popup = {
          kind = 'auto',
        },
        signs = {
          section = { ' ', '' },
          item = { ' ', '' },
        },
        integrations = { diffview = true },
        disable_builtin_notifications = true,
        disable_commit_confirmation = true,
      })

      local group =
        vim.api.nvim_create_augroup('MyCustomNeogitEvents', { clear = true })
      vim.api.nvim_create_autocmd('User', {
        pattern = 'NeogitPushComplete',
        group = group,
        callback = require('neogit').close,
      })

      lmap('gS', function()
        return neogit.open({
          cwd = vim.fn.expand('%:p:h'),
          kind = 'auto',
        })
      end, '[Split] Neogit Git status')

      lmap('gcc', function()
        return neogit.open({ 'commit' })
      end, 'Neogit Git commit')
    end,
  },
}
