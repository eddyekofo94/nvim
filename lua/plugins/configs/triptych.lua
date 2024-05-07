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
