---@type pack.spec
return {
  src = 'https://github.com/kevinhwang91/nvim-bqf',
  data = {
    ft = "qf",
    postload = function()
      require("bqf").setup({
        preview = {
          auto_preview = true,
          win_height = 12,
          win_vheight = 12,
          delay_syntax = 80,
          border = "rounded",
        },
        func_map = {
          vsplit = "v",
          ptoggle = "p",
          stoggle = "s",
        },
      })
    end,
  },
}
