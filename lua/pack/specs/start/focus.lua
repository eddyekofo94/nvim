---@type pack.spec
return {
  src = 'https://github.com/beauwilliams/focus.nvim',
  data = {
    events = { event = 'BufReadPre' },
    enabled = true,
    cmd = {
      'FocusAutoresize',
    },
    postload = function()
      local map = require('utils.key').nmap
      local focus = require('focus')
      local hl = require('utils.hl')

      local ignore_filetypes = {
        'notification_history',
        'nofile',
        'undotree_2',
        'diffpanel_3',
        'Scratch',
        'prompt',
        'NvimTree',
        'snacks_picker_list',
        'snacks_picker*',
        'nvim-tree',
        'qf',
        'git-conflict',
        'dap-repl',
        'dapui_scopes',
        'dapui_stacks',
        'dapui_breakpoints',
        'dapui_console',
        'dapui_watches',
        'dapui_repl',
        'undotree',
        'noice',
        'man',
        'messages',
        'undotree',
        'NeogitStatus',
        'notify',
        'Trouble',
        'diffview',
        'DiffviewFilePanel',
        'DiffviewPanel',
        'diffview*',
        'telescope',
        'toggleterm',
        'lazy',
        'Outline',
        'TelescopePrompt',
        'TelescopeResults',
        'TelescopePreview',
        'DiffviewFilePanel',
        'Diffview*',
        'fzf',
        'FzfLua',
      }

      local ignore_buftypes = {
        'nofile',
        'nofile,fzf',
        'terminal',
        'prompt',
        'fzf',
      }

      local opts = {
        commands = true,
        autoresize = {
          enable = true,
          quickfixheight = 60,
        },
        signcolumn = true,
        excluded_buftypes = ignore_buftypes,
        excluded_filetypes = ignore_filetypes,
        compatible_filetrees = { 'git-conflict', 'oil', 'diffview' },
        ui = {
          absolutenumber_unfocussed = true,
          number = false,
          relativenumber = false,
          hybridnumber = false,
          signcolumn = false,
          cursorline = true,
          winhighlight = false,
        },
      }

      map('<C-\\>', '<cmd>FocusAutoresize<cr>', 'Activate focus')

      map('<leader>vd', '<cmd>FocusSplitDown<CR>', '[Focus] Split horizontally')

      map('<leader>=', function()
        focus.focus_equalise()
      end, 'balance windows')

      map('<leader>vr', '<cmd>FocusSplitRight<cr>', 'Split right')

      map('<leader>vv', function()
        focus.split_nicely()
      end, 'Split nicely')

      local augroup =
        vim.api.nvim_create_augroup('FocusDisable', { clear = true })
      vim.api.nvim_create_autocmd('WinEnter', {
        group = augroup,
        callback = function(_)
          if vim.g._fzf_active then
            vim.b.focus_disable = true
            vim.w.focus_disable = true
          elseif vim.tbl_contains(ignore_buftypes, vim.bo.buftype) then
            vim.b.focus_disable = true
            vim.w.focus_disable = true
          elseif vim.tbl_contains(ignore_filetypes, vim.bo.filetype) then
            vim.b.focus_disable = true
            vim.w.focus_disable = true
          elseif vim.w.focus_disable == true or vim.w.winbar_no_attach == true then
            vim.b.focus_disable = true
            vim.w.focus_disable = true
          else
            vim.b.focus_disable = false
            vim.w.focus_disable = false
          end
        end,
        desc = 'Disable focus autoresize for BufType/FileType',
      })

      vim.api.nvim_create_autocmd('BufEnter', {
        group = augroup,
        callback = function(args)
          if not vim.g._fzf_active then
            vim.b[args.buf].focus_disable = false
          end
        end,
      })

      hl.link('FocusedWindow', 'FocusedWindowBg')
      hl.link('UnfocusedWindow', 'VisualNOS')

      vim.defer_fn(function()
        local ok, resizer = pcall(require, 'focus.modules.resizer')
        if ok then
          local original_split_resizer = resizer.split_resizer
          resizer.split_resizer = function(config, goal)
            if
              vim.g._fzf_active
              or vim.bo.filetype == 'fzf'
              or vim.bo.filetype == 'FzfLua'
              or vim.w.focus_disable == true
              or vim.w.winbar_no_attach == true
            then
              vim.o.winminwidth = 1
              vim.o.winminheight = 1
              vim.o.winwidth = 1
              vim.o.winheight = 1
              return
            end
            return original_split_resizer(config, goal)
          end
        end

        local ok2, utils = pcall(require, 'focus.modules.utils')
        if ok2 then
          local original_is_disabled = utils.is_disabled
          utils.is_disabled = function()
            if
              vim.g._fzf_active
              or vim.bo.filetype == 'fzf'
              or vim.bo.filetype == 'FzfLua'
              or vim.w.focus_disable == true
              or vim.w.winbar_no_attach == true
            then
              return true
            end
            return original_is_disabled()
          end
        end
      end, 100)

      focus.setup(opts)
    end,
  },
}
