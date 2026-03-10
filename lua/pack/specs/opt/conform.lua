---@type pack.spec
return {
  src = 'https://github.com/stevearc/conform.nvim',
  data = {
    ft = {
      'lua',
      'go',
      'json',
      'yaml',
      'javascript',
      'python',
      'sh',
      'zsh',
      'fish',
    },
    postload = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

      require('conform').setup({
        formatters_by_ft = {
          lua = { 'stylua' },
          go = { 'gofumpt', 'goimports_reviser', 'gofmt', 'golines' },
          json = { 'jq' },
          yaml = { 'prettier' },
          javascript = { 'prettierd', 'prettier' },
          python = function(bufnr)
            if
              require('conform').get_formatter_info('ruff_format', bufnr).available
            then
              return { 'ruff_format' }
            else
              return { 'autopep8', 'isort', 'black' }
            end
          end,
          sh = {
            'beautysh',
            'shellcheck',
            'shfmt',
          },
          zsh = { 'beautysh' },
          fish = { 'fish_indent' },
          ['*'] = { 'codespell' },
          ['_'] = { 'trim_whitespace', 'trim_newlines', 'squeeze_blanks' },
        },
        format_on_save = function(bufnr)
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
          end
        end,
        format_after_save = function(bufnr)
          local ignore_filetypes = { 'lua' }
          if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
            return { timeout_ms = 500, lsp_fallback = true }
          end

          local lines = vim.fn
            .system('git diff --unified=0 ' .. vim.fn.bufname(bufnr))
            :gmatch('[^\n\r]+')
          local ranges = {}
          for line in lines do
            if line:find('^@@') then
              local line_nums = line:match('%+.- ')
              if line_nums:find(',') then
                local _, _, first, second = line_nums:find('(%d+),(%d+)')
                table.insert(ranges, {
                  start = { tonumber(first), 0 },
                  ['end'] = { tonumber(first) + tonumber(second), 0 },
                })
              else
                local first = tonumber(line_nums:match('%d+'))
                table.insert(ranges, {
                  start = { first, 0 },
                  ['end'] = { first + 1, 0 },
                })
              end
            end
          end
          local format = require('conform').format
          for _, range in pairs(ranges) do
            format({ range = range })
          end
        end,
        log_level = vim.log.levels.ERROR,
        notify_on_error = true,
        formatters = {},
      })

      local map = require('utils.key').map
      map('n', '<leader>cf', function()
        require('conform').format()
      end, { desc = 'Format current file' })
    end,
  },
}
