return {
  {
    "akinsho/git-conflict.nvim",
    lazy = false,
    event = "BufRead",
    version = "*",
    cmd = { "GitConflictRefresh" },
    config = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "GitConflictDetected",
        callback = function()
          vim.notify("Conflict detected in " .. vim.fn.expand "<afile>")
        end,
      })

      require("git-conflict").setup {
        default_mappings = { -- disable buffer local mapping created by this plugin
          ours = "c<",
          theirs = "c>",
          none = "co",
          both = "c.",
          next = "]x",
          prev = "[x",
        },
        default_commands = true, -- disable commands created by this plugin
        disable_diagnostics = true, -- This will disable the diagnostics in a buffer whilst it is conflicted
        list_opener = "copen", -- command or function to open the conflicts list
        highlights = { -- They must have background color, otherwise the default color will be used
          incoming = "DiffText",
          current = "DiffAdd",
        },
      }
    end,
    keys = {
      { "<Leader>gab", "<cmd>GitConflictChooseBoth<CR>", desc = "choose both" },
      { "<Leader>gan", "<cmd>GitConflictNextConflict<CR>", desc = "move to next conflict" },
      { "<Leader>gac", "<cmd>GitConflictChooseOurs<CR>", desc = "choose current" },
      { "<Leader>gap", "<cmd>GitConflictPrevConflict<CR>", desc = "move to prev conflict" },
      { "<Leader>gai", "<cmd>GitConflictChooseTheirs<CR>", desc = "choose incoming" },
    },
  },
}
