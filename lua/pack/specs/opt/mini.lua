---@type pack.spec
return {
  src = "https://github.com/nvim-mini/mini.nvim",
  data = {
    postload = function()
      require("mini.trailspace").setup()
    end,
  },
}
