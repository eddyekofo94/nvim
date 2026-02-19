---@type pack.spec
return {
  src = 'https://github.com/junegunn/vim-easy-align',
  data = {
    keys = {
      {
        lhs = 'cel',
        mode = { 'n', 'x' },
        opts = { desc = 'Align text' },
      },
      {
        lhs = 'ceL',
        mode = { 'n', 'x' },
        opts = { desc = 'Align text interactively' },
      },
    },
    postload = function()
      vim.g.easy_align_delimiters = {
        ['\\'] = {
          pattern = [[\\\+]],
        },
        ['/'] = {
          pattern = [[//\+\|/\*\|\*/]],
          delimiter_align = 'c',
          ignore_groups = '!Comment',
        },
      }

      vim.keymap.set(
        { 'n', 'x' },
        'cel',
        '<Plug>(EasyAlign)',
        { noremap = false, desc = 'Align text' }
      )
      vim.keymap.set(
        { 'n', 'x' },
        'ceL',
        '<Plug>(LiveEasyAlign)',
        { noremap = false, desc = 'Align text interactively' }
      )
    end,
  },
}
