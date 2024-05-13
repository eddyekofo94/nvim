return {
  "echasnovski/mini.notify",
  version = "*",
  lazy = false,
  enabled = true,
  keys = {
    {
      "<leader>vn",
      function()
        require("mini.notify").show_history()
      end,
      desc = "[N]otifications History",
    },
  },
  opts = {
    lsp_progress = {
      -- oh god please stop annoying me
      enable = false,
    },

    window = {
      -- https://github.com/echasnovski/mini.nvim/blob/a118a964c94543c06d8b1f2f7542535dd2e19d36/doc/mini-notify.txt#L186-L198
      config = {
        anchor = "SE",
        col = vim.o.columns,
        row = vim.o.lines - 2,
        width = math.floor(vim.o.columns * 0.35),
        border = "solid",
      },
      winblend = 10,
    },
  },
  config = function(_, opts)
    require("mini.notify").setup(opts)

    -- Wrap all vim.notify calls with mini.notify
    vim.notify = require("mini.notify").make_notify()
  end,
}
