---@type pack.spec
return {
  src = "https://github.com/echasnovski/mini.ai",
  data = {
    enabled = true,
    postload = function()
      local ai = require("mini.ai")
      local gen_spec = ai.gen_spec

      ai.setup({
        -- Neovim owns `an`/`in` (treesitter incremental selection, |v_an|)
        -- and `al`/`il` ("all lines" / "inner line") since 0.13. Move the
        -- next/last textobjects to the upper-case pair mini.ai recommends in
        -- |MiniAi-default-an-in| so both sets stay reachable.
        mappings = {
          around_next = "aN",
          inside_next = "iN",
          around_last = "aL",
          inside_last = "iL",
        },
        custom_textobjects = {
          f = gen_spec.treesitter({
            a = "@function.outer",
            i = "@function.inner",
          }),
          c = gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
          o = gen_spec.treesitter({ a = "@loop.outer", i = "@loop.inner" }),
          ["if"] = gen_spec.treesitter({
            a = "@conditional.outer",
            i = "@conditional.inner",
          }),
          a = gen_spec.treesitter({
            a = "@parameter.outer",
            i = "@parameter.inner",
          }),
          g = function()
            local from = { line = 1, col = 1 }
            local to = {
              line = vim.fn.line("$"),
              col = math.max(vim.fn.getline("$"):len(), 1),
            }
            return { from = from, to = to }
          end,
        },
      })
    end,
  },
}
