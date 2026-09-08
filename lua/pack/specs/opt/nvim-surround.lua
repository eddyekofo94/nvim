---@type pack.spec
return {
  src = "https://github.com/kylechui/nvim-surround",
  -- The author ships breaking changes across majors, so stay inside 4.x.
  -- `vim.pack` resolves this to the greatest semver tag in range.
  version = vim.version.range("4.x"),
  data = {
    keys = {
      { lhs = "ys", opts = { desc = "Surround" } },
      { lhs = "yss", opts = { desc = "Surround line" } },
      { lhs = "yS", opts = { desc = "Surround in new lines" } },
      { lhs = "ySS", opts = { desc = "Surround line in new lines" } },
      { lhs = "ds", opts = { desc = "Delete surrounding" } },
      { lhs = "cs", opts = { desc = "Change surrounding" } },
      { lhs = "S", mode = "x", opts = { desc = "Surround" } },
      { lhs = "gS", mode = "x", opts = { desc = "Surround in new lines" } },
      { lhs = "<C-g>s", mode = "i", opts = { desc = "Surround" } },
      { lhs = "<C-g>S", mode = "i", opts = { desc = "Surround" } },
    },
    postload = function()
      require("nvim-surround").setup({
        surrounds = {
          -- Bold markers in markdown
          ["<M-*>"] = {
            add = { "**", "**" },
          },
        },
      })
    end,
  },
}
