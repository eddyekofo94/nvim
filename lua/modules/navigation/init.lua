return {
  {
    "simonmclean/triptych.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "nvim-tree/nvim-web-devicons", -- optional
    },
    config = function()
      require "modules.configs.triptych"
      local lmap = require("utils.keymaps").set_leader_keymap

      lmap("<leader>-", "<cmd>Triptych<CR>", "[Triptych] File explorer")
    end,
  },
}
