---@type pack.spec
return {
  src = 'https://github.com/nvim-treesitter/nvim-treesitter',
  version = 'main', -- master branch is deprecated
  data = {
    build = function()
      vim.cmd.packadd('nvim-treesitter')
      require('nvim-treesitter.install').update()
    end,
    cmds = {
      'TSInstall',
      'TSInstallFromGrammar',
      'TSUninstall',
      'TSUpdate',
    },
    -- Skip loading nvim-treesitter for plugin-specific filetypes containing
    -- underscores (e.g. 'cmp_menu') to improve initial cmdline responsiveness
    -- on slower systems
    events = { event = 'FileType', pattern = '[^_]\\+' },
    postload = function()
      local ensure_installed = {
        'javascript',
        'markdown',
        'markdown_inline',
        'yaml',
        'go',
        'regex',
        'json',
        'bash',
        'query',
        'fish',
        'lua',
        'luadoc',
        'cpp',
        'dockerfile',
        'python',
        'java',
        'gitcommit',
        'git_rebase',
        'diff',
        'xml',
        'toml',
      }

      -- 1. Configure the installer
      local ts_install = require('nvim-treesitter.install')
      ts_install.prefer_git = true
      ts_install.compilers = { 'gcc', 'clang' }

      ts_install.install(ensure_installed)
      vim.treesitter.language.register('bash', {
        'sh',
        'csh',
        'zsh',
      })

      vim.treesitter.language.register('ini', 'conf')
      vim.treesitter.language.register('markdown', 'text')
    end,
  },
}
