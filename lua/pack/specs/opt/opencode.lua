---@type pack.spec
return {
  src = 'https://github.com/sudo-tee/opencode.nvim',
  data = {
    deps = {
      'https://github.com/nvim-lua/plenary.nvim',
      {
        src = 'https://github.com/saghen/blink.cmp',
        data = { optional = true },
      },
      {
        src = 'https://github.com/ibhagwan/fzf-lua',
        data = { optional = true },
      },
    },
    cmds = {
      'Opencode',
    },
    keys = {
      lhs = '<Leader>@',
      opts = { desc = 'Toggle opencode' },
    },
    postload = function()
      local baseline_paths = {
        'bun-baseline',
        '~/.bun/bin/bun-baseline',
        '/usr/local/bin/bun-baseline',
        '/opt/homebrew/bin/bun-baseline',
      }
      for _, path in ipairs(baseline_paths) do
        local expanded = vim.fn.expand(path)
        if vim.fn.executable(expanded) == 1 then
          vim.env.BUN_EXE = expanded
          break
        end
      end

      if vim.fn.executable('opencode') == 0 then
        vim.notify(
          '[Opencode.nvim] command `opencode` not found',
          vim.log.levels.ERROR
        )
        return
      end

      require('opencode').setup({
        default_global_keymaps = false,
        default_mode = 'build',
        keymap_prefix = '<leader>o',
        ui = {
          icons = { preset = vim.g.has_nf and 'nerdfonts' or 'text' },
          input = { text = { wrap = true } },
        },
        context = {
          cursor_data = {
            enabled = true,
          },
        },
        keymap = {
          editor = {
            ['<leader>og'] = { 'toggle' },
            ['<leader>ot'] = { 'toggle_focus' },
            ['<leader>od'] = { 'diff_open' },
            ['<leader>o]'] = { 'diff_next' },
            ['<leader>o['] = { 'diff_prev' },
            ['<leader>oc'] = { 'diff_close' },
          },
          input_window = {
            ['<cr>'] = {
              'submit_input_prompt',
              mode = 'n',
            },
            ['<m-cr>'] = {
              'submit_input_prompt',
              mode = { 'i', 'n' },
            },
            ['<tab>'] = false,
            ['<esc>'] = false,
          },
          output_window = {
            ['<esc>'] = false,
          },
        },
      })

      local opencode_api = require('opencode.api')

      vim.keymap.set(
        'n',
        '<Leader>@',
        opencode_api.toggle_focus,
        { desc = 'Toggle opencode panel' }
      )
      vim.keymap.set(
        'n',
        '[@',
        opencode_api.diff_prev,
        { desc = 'Navigate to previous file diff' }
      )
      vim.keymap.set(
        'n',
        ']@',
        opencode_api.diff_next,
        { desc = 'Navigate to next file diff' }
      )

      local group = vim.api.nvim_create_augroup('opencode.settings', {})

      vim.api.nvim_create_autocmd('FileType', {
        desc = 'FileType settings for opencode buffers.',
        pattern = 'opencode*',
        group = group,
        callback = function(args)
          vim.b[args.buf].winbar_no_attach = true
        end,
      })

      vim.api.nvim_create_autocmd('BufWinEnter', {
        desc = 'Opencode window settings.',
        group = group,
        callback = function(args)
          if not vim.startswith(vim.bo[args.buf].ft, 'opencode') then
            return
          end
          vim.b[args.buf].focus_disable = true
          for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
            if vim.api.nvim_win_is_valid(win) then
              vim.w[win].focus_disable = true
            end
          end
        end,
      })

      local hl = require('utils.hl')

      hl.persist(function()
        hl.set(0, 'OpenCodeNormal', { link = 'NormalSpecial' })
        hl.set(0, 'OpenCodeBackground', { link = 'NormalSpecial' })
        hl.set(0, 'OpenCodeDiffAdd', { link = 'DiffAdd' })
        hl.set(0, 'OpencodeDiffDelete', { link = 'DiffDelete' })
        hl.set(0, 'OpencodeAgentBuild', { link = 'Todo' })
        hl.set(0, 'OpencodeInputLegend', { link = 'SpecialKey' })
        hl.set(
          0,
          'OpenCodeSessionDescription',
          { bg = 'OpenCodeNormal', fg = 'Comment' }
        )
        hl.set(0, 'OpenCodeHint', { bg = 'OpenCodeNormal', fg = 'Comment' })
        hl.set(
          0,
          'OpenCodeContextBar',
          { bg = 'OpenCodeNormal', fg = 'WinBar' }
        )
      end)
    end,
  },
}
