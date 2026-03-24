---@type pack.spec
return {
  src = "https://github.com/bassamsdata/namu.nvim",
  data = {
    event = "LspAttach",
    postload = function()
      require("namu").setup {
        global = {},
        namu_symbols = {
          options = {},
        },
      }

      vim.keymap.set("n", "<C-n>", ":Namu symbols<cr>", {
        desc = "Jump to LSP symbol",
        silent = true,
      })
      vim.keymap.set("n", "<leader>nw", ":Namu workspace<cr>", {
        desc = "LSP Symbols - Workspace",
        silent = true,
      })
    end,
  },
}
