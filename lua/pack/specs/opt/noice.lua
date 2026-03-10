---@type pack.spec
return {
  src = 'https://github.com/folke/noice.nvim',
  data = {
    dependencies = { 'MunifTanjim/nui.nvim' },
    postload = function()
      require('noice').setup({
        cmdline = {
          enabled = true,
          view = 'cmdline',
          format = {
            search_down = { view = 'cmdline' },
            search_up = { view = 'cmdline' },
          },
          opts = {},
        },
        routes = {
          {
            view = 'mini',
            filter = {
              event = 'msg_show',
              find = 'substitutions',
              error = true,
            },
          },
          { filter = { find = 'fewer lines;' }, opts = { skip = true } },
          { filter = { find = 'more line;' }, opts = { skip = true } },
          { filter = { find = 'more lines;' }, opts = { skip = true } },
          { filter = { find = 'less;' }, opts = { skip = true } },
          { filter = { find = 'change;' }, opts = { skip = true } },
          { filter = { find = 'changes;' }, opts = { skip = true } },
          { filter = { find = 'indent' }, opts = { skip = true } },
          { filter = { find = 'move' }, opts = { skip = true } },
          {
            filter = { find = 'No information available' },
            opts = { skip = true },
          },
        },
        messages = {
          enabled = true,
          view = 'notify',
          view_error = 'notify',
          view_warn = 'notify',
          view_history = 'messages',
          view_search = 'virtualtext',
          filter = {
            any = {
              { event = 'notify' },
              { error = true },
              { warning = true },
              { event = 'msg_show', kind = { '' } },
              { event = 'lsp', kind = 'message' },
            },
          },
        },
        popupmenu = {
          enabled = false,
          backend = 'nui',
          kind_icons = {},
        },
        commands = {
          history = {
            view = 'split',
            opts = { enter = true, format = 'details' },
            filter = {
              any = {
                { event = 'msg_show' },
                { error = true },
                { warning = true },
                { event = 'lsp', kind = 'message' },
              },
            },
          },
          last = {
            view = 'popup',
            opts = { enter = true, format = 'details' },
            filter = {
              any = {
                { event = 'notify' },
                { error = true },
                { warning = true },
                { event = 'msg_show', kind = { '' } },
                { event = 'lsp', kind = 'message' },
              },
            },
            filter_opts = { count = 1 },
          },
          errors = {
            view = 'popup',
            opts = { enter = true, format = 'details' },
            filter = { error = true },
            filter_opts = { reverse = true },
          },
        },
        notify = {
          enabled = false,
          view = 'notify',
        },
        lsp = {
          documentation = {
            enabled = false,
          },
          progress = {
            enabled = false,
          },
          hover = {
            enabled = false,
          },
          signature = {
            enabled = false,
          },
          message = {
            enabled = false,
          },
        },
        markdown = {
          hover = {
            ['|(%S-)|'] = vim.cmd.help,
            ['%[.-%]%((%S-)%)'] = require('noice.util').open,
          },
          highlights = {
            ['|%S-|'] = '@text.reference',
            ['@%S+'] = '@parameter',
            ['^%s*(Parameters:)'] = '@text.title',
            ['^%s*(Return:)'] = '@text.title',
            ['^%s*(See also:)'] = '@text.title',
            ['{%S-}'] = '@parameter',
          },
        },
        health = {
          checker = true,
        },
        smart_move = {
          enabled = true,
          excluded_filetypes = { 'cmp_menu', 'cmp_docs', 'notify' },
        },
        presets = {
          bottom_search = true,
          command_palette = true,
          long_message_to_split = true,
          inc_rename = false,
          lsp_doc_border = false,
        },
        throttle = 1000 / 30,
        views = {
          cmdline_popup = {
            border = {
              style = 'none',
              padding = { 1, 2 },
            },
            filter_options = {},
            win_options = {
              winhighlight = 'NormalFloat:NormalFloat,FloatBorder:FloatBorder',
            },
          },
        },
        status = {},
        format = {},
        keys = {
          {
            '<S-Enter>',
            function()
              require('noice').redirect(vim.fn.getcmdline())
            end,
            mode = 'c',
            desc = 'Redirect Cmdline',
          },
        },
      })

      vim.keymap.set('n', '<leader>nh', '<cmd>NoiceAll<cr>', { silent = true })

      vim.api.nvim_create_user_command('NoiceLatest', function()
        vim.cmd('Noice history')
        vim.defer_fn(function()
          local win = vim.api.nvim_get_current_win()
          local buf = vim.api.nvim_win_get_buf(win)
          local line_count = vim.api.nvim_buf_line_count(buf)
          if
            vim.bo[buf].filetype == 'noice'
            or vim.bo[buf].buftype == 'nofile'
          then
            vim.api.nvim_win_set_cursor(win, { line_count, 0 })
            vim.cmd('normal! zz')
          end
        end, 50)
      end, {})
    end,
  },
}
