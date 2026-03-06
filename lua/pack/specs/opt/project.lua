---@type pack.spec
return {
  src = 'https://github.com/DrKJeff16/project.nvim',
  data = {
    deps = {
      'https://github.com/ibhagwan/fzf-lua',
    },
    postload = function()
      vim.defer_fn(function()
        require('project').setup({
          fzf_lua = {
            enabled = true,
          },
        })
      end, 100)
    end,
  },
}
