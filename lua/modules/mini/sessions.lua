return {
  "echasnovski/mini.sessions",
  lazy = false,
  enabled = true,
  priority = 100,
  event = "VimEnter",
  keys = {
    {
      "<leader>Sw",
      '<cmd>:lua MiniSessions.write((vim.fn.getcwd():gsub("/", "_")))<CR>',
      desc = "Session Write",
    },
    {
      "<leader>SW",
      ':lua MiniSessions.write((vim.fn.getcwd():gsub("/", "_")))',
      desc = "Session Write Custom",
    },
    { "<leader>Ss", "<cmd>:lua MiniSessions.select()<CR>", desc = "Session Select" },
    {
      "<leader>Sd",
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

    --  TODO: 2024-05-27 - Make session per cwd
    return {
      autoread = true,
      directory = vim.fn.stdpath "state" .. "/sessions/",
      file = vim.fn.getcwd() .. "session.vim",
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
  config = function()
    local H = {}
    local M = {}

    require("mini.sessions").setup()

    M.save = function()
      local res = H.get_session_from_user "Save session as: "
      if res ~= nil then
        MiniSessions.write(res)
      end
    end

    -- For autocompletion of session name
    -- Config._session_complete = function(arg_lead)
    --   return vim.tbl_filter(function(x)
    --     return x:find(arg_lead, 1, true) ~= nil
    --   end, vim.tbl_keys(MiniSessions.detected))
    -- end

    H.get_session_from_user = function(prompt)
      local completion = "customlist,v:lua.Config._session_complete"
      local ok, res = pcall(vim.fn.input, {
        prompt = prompt,
        cancelreturn = false,
        completion = completion,
      })
      if not ok or res == false then
        return nil
      end
      return res
    end
  end,
}
