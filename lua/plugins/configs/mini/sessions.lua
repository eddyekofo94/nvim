return {
  "echasnovski/mini.sessions",
  lazy = false,
  enabled = true,
  priority = 100,
  event = "VimEnter",
  keys = {
    {
      "<leader>sw",
      '<cmd>:lua MiniSessions.write((vim.fn.getcwd():gsub("/", "_")))<CR>',
      desc = "Session Write",
    },
    {
      "<leader>sW",
      ':lua MiniSessions.write((vim.fn.getcwd():gsub("/", "_")))',
      desc = "Session Write Custom",
    },
    { "<leader>ss", "<cmd>:lua MiniSessions.select()<CR>", desc = "Session Select" },
    {
      "<leader>sd",
      '<cmd>:lua MiniSessions.delete((vim.fn.getcwd():gsub("/", "_")))<CR>',
      desc = "Session Delete",
    },
  },
  version = "*",
  opts = function()
    -- local function shutdown_term()
    --   -- local terms = require "toggleterm.terminal"
    --   -- local nvterm = require "nvterm.terminal"
    --   --
    --   -- for _, buf in ipairs(nvterm.list_active_terms "buf") do
    --   --   vim.cmd("bd! " .. tostring(buf))
    --   -- end
    -- end
    return {
      autoread = true,
      directory = vim.fn.stdpath "state" .. "/sessions/",
      file = "session.vim",
      -- Whether to force possibly harmful actions (meaning depends on function)
      force = { read = false, write = true, delete = true },
      hooks = {
        -- Before successful action
        pre = { read = nil, write = nil, delete = nil },
        -- After successful action
        post = { read = nil, write = nil, delete = nil },
      },
    }
  end,
  config = true,
}
