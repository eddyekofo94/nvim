local function is_git_repo()
  local stat = vim.loop.fs_stat ".git"
  return (stat and stat.type) or false
end

return {
  "echasnovski/mini.sessions",
  enabled = true,
  lazy = false,
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
  config = function()
    if not is_git_repo() then
      return
    end

    local cwd = vim.fn.getcwd()
    local project_folder_name = cwd:match "^.+/(.+)$"

    -- close bad buffers (neo-tree, trouble, etc) to avoid saving them in the session
    -- otherwise, loading the session would open them with the wrong size
    local close_bad_buffers = function()
      local buffer_numbers = vim.api.nvim_list_bufs()
      for _, buffer_number in pairs(buffer_numbers) do
        local buffer_type = vim.api.nvim_buf_get_option(buffer_number, "buftype")
        local buffer_file_type = vim.api.nvim_buf_get_option(buffer_number, "filetype")

        if buffer_type == "nofile" or buffer_file_type == "norg" then
          vim.api.nvim_buf_delete(buffer_number, { force = true })
        end
      end
    end

    local count_open_file_buffers = function()
      local count = 0
      for _, buffer_number in pairs(vim.api.nvim_list_bufs()) do
        local buffer_name = vim.api.nvim_buf_get_name(buffer_number)
        local buffer_file_type = vim.api.nvim_buf_get_option(buffer_number, "filetype")

        if buffer_name ~= "" and buffer_file_type ~= "norg" then
          count = count + 1
        end
      end
      return count
    end

    local minisessions = require "mini.sessions"
    minisessions.setup {
      autoread = true,
      autowrite = true,
      directory = vim.fn.stdpath "state" .. "/sessions/" .. project_folder_name .. "/",
      file = "Session.vim",
      force = { read = false, write = true, delete = false },
      hooks = {
        pre = { read = nil, write = close_bad_buffers, delete = nil },
        post = { read = nil, write = nil, delete = nil },
      },
      verbose = { read = false, write = true, delete = true },
    }

    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        close_bad_buffers()
        local number_of_open_buffers = count_open_file_buffers()
        if number_of_open_buffers > 0 then
          minisessions.write(project_folder_name .. ".vim")
        end
      end,
    })
  end,
}

-- return {
--   "echasnovski/mini.sessions",
--   lazy = false,
--   enabled = true,
--   priority = 100,
--   event = "VimEnter",
--   keys = {
--     {
--       "<leader>Sw",
--       '<cmd>:lua MiniSessions.write((vim.fn.getcwd():gsub("/", "_")))<CR>',
--       desc = "Session Write",
--     },
--     {
--       "<leader>SW",
--       ':lua MiniSessions.write((vim.fn.getcwd():gsub("/", "_")))',
--       desc = "Session Write Custom",
--     },
--     { "<leader>Ss", "<cmd>:lua MiniSessions.select()<CR>", desc = "Session Select" },
--     {
--       "<leader>Sd",
--       '<cmd>:lua MiniSessions.delete((vim.fn.getcwd():gsub("/", "_")))<CR>',
--       desc = "Session Delete",
--     },
--   },
--   version = "*",
--   opts = function()
--     -- local function shutdown_term()
--     --   -- local terms = require "toggleterm.terminal"
--     --   -- local nvterm = require "nvterm.terminal"
--     --   --
--     --   -- for _, buf in ipairs(nvterm.list_active_terms "buf") do
--     --   --   vim.cmd("bd! " .. tostring(buf))
--     --   -- end
--     -- end
--
--     --  TODO: 2024-05-27 - Make session per cwd
--     return {
--       autoread = false,
--       directory = vim.fn.stdpath "state" .. "/sessions/",
--       file = "session.vim",
--       -- Whether to force possibly harmful actions (meaning depends on function)
--       force = { read = false, write = true, delete = true },
--       hooks = {
--         -- Before successful action
--         pre = { read = nil, write = nil, delete = nil },
--         -- After successful action
--         post = { read = nil, write = nil, delete = nil },
--       },
--     }
--   end,
--   config = function()
--     local H = {}
--     local M = {}
--
--     require("mini.sessions").setup {
--       autoread = true,
--       directory = vim.fn.stdpath "state" .. "/sessions/",
--       -- file = vim.fn.getcwd() .. "session.vim",
--       file = "session.vim",
--       -- Whether to force possibly harmful actions (meaning depends on function)
--       force = { read = false, write = true, delete = true },
--       hooks = {
--         -- Before successful action
--         pre = { read = nil, write = nil, delete = nil },
--         -- After successful action
--         post = { read = nil, write = nil, delete = nil },
--       },
--     }
--
--     M.save = function()
--       local res = H.get_session_from_user "Save session as: "
--       if res ~= nil then
--         MiniSessions.write(res)
--       end
--     end
--
--     -- For autocompletion of session name
--     -- Config._session_complete = function(arg_lead)
--     --   return vim.tbl_filter(function(x)
--     --     return x:find(arg_lead, 1, true) ~= nil
--     --   end, vim.tbl_keys(MiniSessions.detected))
--     -- end
--
--     H.get_session_from_user = function(prompt)
--       local completion = "customlist,v:lua.Config._session_complete"
--       local ok, res = pcall(vim.fn.input, {
--         prompt = prompt,
--         cancelreturn = false,
--         completion = completion,
--       })
--       if not ok or res == false then
--         return nil
--       end
--       return res
--     end
--   end,
-- }
