---@type pack.spec
return {
  src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim',
  data = {
    event = 'VeryLazy',
    dependencies = { 'williamboman/mason.nvim' },
    postload = function()
      require('mason-tool-installer').setup {
        ensure_installed = {
          'lua-language-server',
          'gopls',
          'pyright',
          'stylua',
          'shfmt',
          'prettier',
        },
        auto_install = true,
      }
    end,
  },
}
