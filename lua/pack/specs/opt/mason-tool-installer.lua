---@type pack.spec
return {
  src = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim',
  data = {
    deps = {
      { src = 'https://github.com/williamboman/mason.nvim' },
    },
    cmds = { 'MasonToolsInstall', 'MasonToolsUpdate', 'MasonToolsClean' },
    postload = function()
      require('mason-tool-installer').setup({
        ensure_installed = {
          'lua-language-server',
          'gopls',
          'pyright',
          'stylua',
          'shfmt',
          'prettier',
        },
        auto_install = true,
      })
    end,
  },
}
