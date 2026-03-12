---@type pack.spec
return {
  src = 'https://github.com/karb94/neoscroll.nvim',
  data = {
    events = { event = 'FileType' },
    enabled = true,
    postload = function()
      require('neoscroll').setup({
        easing_function = 'quadratic',
        cursor_scroll_expr = '',
        mappings = { '<C-u>', '<C-d>', 'zt', 'zz', 'zb' },
        pre_hook = function()
          vim.wo.cursorline = vim.wo.cursorline
        end,
        post_hook = function()
          vim.wo.cursorline = vim.wo.cursorline
        end,
        stop_eof = true,
        use_local_scrolloff = false,
        scroll_smooth = true,
        scroll_steps = 5,
      })
    end,
  },
}
