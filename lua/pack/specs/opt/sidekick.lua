---@type pack.spec
return {
  src = 'https://github.com/folke/sidekick.nvim',
  data = {
    event = { event = 'User', pattern = 'VeryLazy' },
    deps = {
      { src = 'https://github.com/zbirenbaum/copilot.lua' },
    },
    postload = function()
      local sidekick_desc = function(desc)
        local ok, utils = pcall(require, 'sidekick.utils')
        if ok then
          return utils.plugin_keymap_desc
              and utils.plugin_keymap_desc('Sidekick', desc)
            or desc
        end
        return desc
      end

      local default_ai_tool = 'opencode'

      require('sidekick').setup({
        nes = {
          enabled = false,
        },
        cli = {
          mux = {
            backend = 'tmux',
            enabled = true,
            create = 'terminal',
          },
        },
      })

      local cli = require('sidekick.cli')

      local nmap = require('utils.key').nmap
      local map = require('utils.key').map

      nmap('<tab>', function()
        if not require('sidekick').nes_jump_or_apply() then
          return '<Tab>'
        end
      end, {
        expr = true,
        desc = sidekick_desc('Goto/Apply next edit suggestion'),
      })

      nmap('<leader>aa', function()
        cli.toggle()
      end, { desc = sidekick_desc('Toggle CLI') })

      nmap('<leader>as', function()
        cli.select({ name = default_ai_tool })
      end, { desc = sidekick_desc('Select CLI') })

      nmap('<leader>aD', function()
        cli.close()
      end, { desc = sidekick_desc('Detach a CLI session') })

      nmap('<leader>af', function()
        cli.send({ msg = '{file}', name = default_ai_tool })
      end, { desc = sidekick_desc('Send file') })

      nmap('<leader>ap', function()
        cli.prompt({ name = default_ai_tool })
      end, { desc = sidekick_desc('Select prompt') })

      nmap('<leader>ao', function()
        cli.toggle({ name = 'opencode', focus = true })
      end, { desc = sidekick_desc('Toggle opencode') })

      map('x', '<leader>at', function()
        cli.send({ msg = '{this}', name = default_ai_tool })
      end, { desc = sidekick_desc('Send this') })

      map('x', '<leader>av', function()
        cli.send({ msg = '{selection}', name = default_ai_tool })
      end, { desc = sidekick_desc('Send visual selection content') })

      map('x', '<leader>ad', function()
        cli.send({ msg = '{diagnostics}', name = default_ai_tool })
      end, { desc = sidekick_desc('Send selected diagnostics') })

      map('x', '<leader>ap', function()
        cli.prompt({ name = default_ai_tool })
      end, { desc = sidekick_desc('Select prompt') })
    end,
  },
}
