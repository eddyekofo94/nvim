---@type pack.spec
return {
  src = 'https://github.com/nvim-treesitter/nvim-treesitter-context',
  data = {
    event = 'BufReadPre',
    postload = function()
      require('treesitter-context').setup({
        enable = true,
        max_lines = 3,
        multiline_threshold = 20,
        max_window_height = 0,
        line_numbers = true,
        trim_scope = 'outer',
        zindex = 20,
        mode = 'cursor',
        separator = nil,
        patterns = {
          default = {
            'class',
            'function',
            'method',
            'for',
            'while',
            'if',
            'switch',
            'case',
            'const',
          },
        },
      })
    end,
  },
}
