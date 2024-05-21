return {
  {
    "ss",
    mode = { "n", "o", "x" },
    function()
      require("flash").jump()
    end,
    desc = "Flash",
  },
  -- { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
  {
    "r",
    mode = "o",
    function()
      require("flash").remote()
    end,
    desc = "Remote Flash",
  },
  {
    "R",
    mode = { "o", "x" },
    function()
      require("flash").treesitter_search()
    end,
    desc = "Treesitter Search",
  },
  {
    "<c-s>",
    mode = { "c" },
    function()
      require("flash").toggle()
    end,
    desc = "Toggle Flash Search",
  },
  {
    "<leader>dd",
    mode = { "n", "x", "o" },
    function()
      require("flash").jump {
        matcher = function(win)
          ---@param diag Diagnostic
          return vim.tbl_map(function(diag)
            return {
              pos = { diag.lnum + 1, diag.col },
              end_pos = { diag.end_lnum + 1, diag.end_col - 1 },
            }
          end, vim.diagnostic.get(vim.api.nvim_win_get_buf(win)))
        end,
        action = function(match, state)
          vim.api.nvim_win_call(match.win, function()
            vim.api.nvim_win_set_cursor(match.win, match.pos)
            vim.diagnostic.open_float()
          end)
          state:restore()
        end,
      }
    end,
    desc = "Flash Diagnostic",
  },
}
-- local keymap = require("utils.keymaps").set_keymap
-- keymap({ "n", "o", "x" }, "ss", function()
--   require("flash").jump()
-- end, "Flash")
--
-- keymap({ "o" }, "r", function()
--   require("flash").remote()
-- end, "Remote Flash")
--
-- keymap({ "o", "x" }, "R", function()
--   require("flash").treesitter_search()
-- end, "Treesitter Search")
--
-- keymap("c", "<c-s>", function()
--   require("flash").toggle()
-- end, "Toggle Flash Search")
