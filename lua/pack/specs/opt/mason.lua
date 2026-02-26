---@type pack.spec
return {
  src = 'https://github.com/williamboman/mason.nvim',
  data = {
    cmd = { 'Mason', 'MasonInstall', 'MasonInstallAll', 'MasonUpdate' },
    event = 'VeryLazy',
    postload = function()
      require('mason').setup {
        ui = {
          border = 'rounded',
          icons = {
            package_installed = '✓',
            package_pending = '➜',
            package_uninstalled = '✗',
          },
        },
      }
    end,
  },
}
