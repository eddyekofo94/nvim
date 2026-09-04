---@type pack.spec
return {
  src = "https://github.com/folke/lazydev.nvim",
  data = {
    ft = "lua",
    postload = function()
      require("lazydev").setup({
        library = {
          -- Neovim ships the luv type definitions, so the archived
          -- `Bilal2453/luvit-meta` plugin is no longer a dependency.
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
      })
    end,
  },
}
