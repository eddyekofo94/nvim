---@type pack.spec
return {
  src = 'https://github.com/dgagn/diagflow.nvim',
  data = {
    event = 'LspAttach',
    postload = function()
      require('diagflow').setup({
        enable = function()
          return vim.bo.filetype ~= 'lazy'
        end,
        inline_padding_left = 5,
        placement = 'top',
        text_align = 'right',
        show_sign = true,
        scope = 'cursor',
      })
    end,
  },
}
