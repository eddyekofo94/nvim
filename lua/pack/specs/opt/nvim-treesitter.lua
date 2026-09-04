---@type pack.spec
return {
  src = "https://github.com/nvim-treesitter/nvim-treesitter",
  version = "main", -- master branch is deprecated
  data = {
    -- The `main` branch does not support lazy-loading (README), so this spec
    -- carries no `cmds`/`events` trigger: `:TSInstall`, `:TSUpdate`,
    -- `:TSUninstall` and `:TSLog` are defined by the plugin itself once it is
    -- loaded eagerly on startup.
    build = function()
      vim.cmd.packadd("nvim-treesitter")
      require("nvim-treesitter").update():wait()
    end,
    postload = function()
      local ensure_installed = {
        "javascript",
        "markdown",
        "markdown_inline",
        "yaml",
        "go",
        "regex",
        "json",
        "bash",
        "query",
        "fish",
        "lua",
        "luadoc",
        "cpp",
        "dockerfile",
        "python",
        "java",
        "gitcommit",
        "git_rebase",
        "diff",
        "xml",
        "toml",
        "swift",
      }

      -- `install.prefer_git` and `install.compilers` were removed with the
      -- `master` branch; `main` downloads tarballs and picks the compiler
      -- itself.
      require("nvim-treesitter").install(ensure_installed)

      vim.treesitter.language.register("bash", {
        "sh",
        "csh",
        "zsh",
      })

      vim.treesitter.language.register("ini", "conf")
      vim.treesitter.language.register("markdown", "text")
    end,
  },
}
