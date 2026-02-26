---@type pack.spec
return {
  src = 'https://github.com/willothy/flatten.nvim',
  data = {
    event = 'BufReadPre',
    postload = function()
      require('flatten').setup {
        window = {
          open = 'current',
        },
        hooks = {
          post_open = function(bufnr, winnr, ft, is_blocking)
            if is_blocking then
              -- If it's a git commit or similar, maybe stay in the terminal
            else
              vim.api.nvim_set_current_win(winnr)
            end
          end,
          block_end = function()
            vim.schedule(function()
              vim.cmd 'unhide'
            end)
          end,
        },
      }
    end,
  },
}
