---@type pack.spec
return {
  src = 'https://github.com/zbirenbaum/copilot.lua',
  data = {
    cmd = { 'Copilot' },
    ft = { 'markdown', 'sh' },
    postload = function()
      require('copilot').setup({
        filetypes = {
          markdown = true,
          sh = function()
            if
              string.match(
                vim.fs.basename(vim.api.nvim_buf_get_name(0)),
                '^%.env.*'
              )
            then
              return false
            end
            return true
          end,
        },
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            accept = '<C-j>',
            next = '<M-]>',
            prev = '<M-[>',
            dismiss = '<C-R>',
          },
        },
      })
    end,
  },
}
