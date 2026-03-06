---@type pack.spec
return {
  src = 'https://github.com/williamboman/mason.nvim',
  data = {
    cmds = { 'Mason', 'MasonInstall', 'MasonInstallAll', 'MasonUpdate' },
    init = function()
      -- Prepend Mason's bin dir to PATH so mason-installed LSP servers
      -- are found by vim.fn.executable() before mason.nvim is loaded
      local mason_bin = vim.fs.joinpath(vim.fn.stdpath('data'), 'mason', 'bin')
      if not vim.env.PATH:find(mason_bin, 1, true) then
        vim.env.PATH = mason_bin .. ':' .. vim.env.PATH
      end
    end,
    postload = function()
      require('mason').setup({
        ui = {
          border = 'rounded',
          icons = {
            package_installed = '✓',
            package_pending = '➜',
            package_uninstalled = '✗',
          },
        },
      })
    end,
  },
}
