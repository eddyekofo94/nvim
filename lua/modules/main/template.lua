return {
  "glepnir/template.nvim",
  config = function()
    require("template").setup {
      -- Path where your templates are stored
      -- temp_dir = '~/.config/nvim/templates',
      temp_dir = vim.fn.stdpath "config" .. "templates",

      -- Auto-detect file types or set manually

      patterns = {
        -- Define patterns for your templates
        "*.cpp",
        "*.js",
        "*.py",
        "*.go",
        "*.java",
        "*.kotlin",
      },

      -- Automatically apply templates based on patterns
      auto_apply = false,
      apply_in_place = true,
    }
  end,
}
