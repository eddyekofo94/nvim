return {
  "cshuaimin/ssr.nvim",
  enabled = true,
  keys = {
    {
      "<leader>r",
      function()
        require("ssr").open()
      end,
      mode = { "n", "x" },
      desc = "Structural Replace",
    },
  },
}
