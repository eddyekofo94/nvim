---@type pack.spec
return {
  src = 'https://github.com/echasnovski/mini.ai',
  data = {
    event = 'VeryLazy',
    postload = function()
      local ai = require('mini.ai')
      local gen_spec = ai.gen_spec

      ai.setup {
        mappings = {
          around_next = 'an',
          inside_next = 'in',
          around_last = 'al',
          inside_last = 'il',
        },
        custom_textobjects = {
          f = gen_spec.treesitter { a = '@function.outer', i = '@function.inner' },
          c = gen_spec.treesitter { a = '@class.outer', i = '@class.inner' },
          o = gen_spec.treesitter { a = '@loop.outer', i = '@loop.inner' },
          ['if'] = gen_spec.treesitter { a = '@conditional.outer', i = '@conditional.inner' },
          a = gen_spec.treesitter { a = '@parameter.outer', i = '@parameter.inner' },
          g = function()
            local from = { line = 1, col = 1 }
            local to = { line = vim.fn.line '$', col = math.max(vim.fn.getline('$'):len(), 1) }
            return { from = from, to = to }
          end,
        },
      }
    end,
  },
}
