return {
  {
    "simonmclean/triptych.nvim",
    event = "VeryLazy",
    enabled = true,
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "nvim-tree/nvim-web-devicons", -- optional
    },
    keys = {
      "<leader>-",
      "<cmd>Triptych<CR>",
      "[Triptych] File explorer",
    },
    config = function()
      local lmap = require("utils.keymaps").set_leader_keymap

      lmap("-", "<cmd>Triptych<CR>", "[Triptych] File explorer")
      require("triptych").setup {
        mappings = {
          nav_left = { "h", "-" },
          quit = { "q", "<esc>" },
        },
        highlights = { -- Highlight groups to use. See `:highlight` or `:h highlight`
          file_names = "NONE",
          directory_names = "NONE",
        },
        extension_mappings = {
          ["<c-.>"] = {
            mode = "n",
            fn = function(target)
              require("telescope.builtin").find_files {
                search_dirs = { target.path },
              }
            end,
          },
          ["<c-/>"] = {
            mode = "n",
            fn = function(target)
              require("telescope.builtin").live_grep {
                search_dirs = { target.path },
              }
            end,
          },
        },
      }
    end,
  },
}
