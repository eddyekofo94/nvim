return {
  { -- convenience file operations
    "chrisgrieser/nvim-genghis",
    external_dependencies = "macos-trash",
    dependencies = "stevearc/dressing.nvim",
    init = function()
      vim.g.genghis_disable_commands = true
    end,
    keys = {
			-- stylua: ignore start
			{"<leader>Bp", function() require("genghis").copyFilepathWithTilde() end, desc = " Copy path (with ~)" },
			{"<leader>BP", function() require("genghis").copyRelativePath() end, desc = " Copy mini.fuzzyrelative path" },
			{"<leader>Bf", function() require("genghis").copyFilename() end, desc = " Copy filename" },
			{"<leader>Br", function() require("genghis").renameFile() end, desc = " Rename file" },
			{"<D-m>", function() require("genghis").moveToFolderInCwd() end, desc = " Move file" },
			{"<leader>Bx", function() require("genghis").chmodx() end, desc = " chmod +x" },
			{"<leader>Bd", function() require("genghis").duplicateFile() end, desc = " Duplicate file" },
			{"<D-BS>", function() require("genghis").trashFile() end, desc = " Move file to trash" },
			{"<D-n>", function() require("genghis").createNewFile() end, desc = " Create new file" },
			{"<leader>BX", function() require("genghis").moveSelectionToNewFile() end, mode = "x", desc = " Selection to new file" },
      -- stylua: ignore end
    },
  },
}
