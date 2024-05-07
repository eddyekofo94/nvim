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
