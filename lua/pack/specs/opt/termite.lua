---@type pack.spec
return {
  src = "https://github.com/ruicsh/termite.nvim",
  data = {
    enabled = false,
    optional = true,
    cmd = { "Termite" },
    postload = function()
      local termite = require "termite"
      termite.setup {
        position = "down",
      }

      vim.keymap.set("n", "<A-i>", function()
        termite.toggle()
      end, { desc = "Toggle terminals" })

      vim.keymap.set("t", "<A-i>", function()
        termite.toggle()
      end, { desc = "Toggle terminals" })

      vim.keymap.set({ "n", "t" }, "<A-o>", function()
        termite.toggle_maximize()
      end, { desc = "Toggle terminal fullscreen" })

      vim.keymap.set("t", "<A-|>", function()
        termite.create()
      end, { desc = "Create new terminal" })

      vim.api.nvim_create_user_command("VSTerm", function()
        termite.create()
      end, { desc = "Open terminal" })

      vim.api.nvim_create_user_command("STerm", function()
        termite.create()
      end, { desc = "Open terminal" })

      vim.api.nvim_create_user_command("BTerm", function()
        termite.create()
      end, { desc = "Open terminal" })

      vim.api.nvim_create_user_command("FTerm", function(opts)
        local cmd = opts.args and #opts.args > 0 and opts.args or vim.o.shell
        termite.create(cmd)
      end, { nargs = "?", desc = "Open terminal fullscreen" })

      vim.api.nvim_create_user_command("LazyGit", function()
        termite.create "lazygit"
      end, { desc = "Open LazyGit fullscreen" })
    end,
  },
}
