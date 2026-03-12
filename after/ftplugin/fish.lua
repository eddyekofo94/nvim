vim.bo.commentstring = "# %s"
vim.opt_local.formatoptions:remove "t"

local hl = require "utils.hl"
hl.persist(function()
  hl.set(0, "@string", { link = "String" })
  hl.set(0, "@string.escape", { link = "SpecialChar" })
  hl.set(0, "@string.special", { link = "Special" })
  hl.set(0, "@string.special.command", { link = "Special" })

  hl.set(0, "@comment", { link = "Comment" })
  hl.set(0, "@keyword", { link = "Keyword" })
  hl.set(0, "@keyword.operator", { link = "Operator" })
  hl.set(0, "@function", { link = "Function" })
  hl.set(0, "@function.builtin", { link = "Builtin" })
  hl.set(0, "@operator", { link = "Operator" })
  hl.set(0, "@variable", { link = "Normal" })
  hl.set(0, "@variable.builtin", { link = "Builtin" })
  hl.set(0, "@number", { link = "Number" })
  hl.set(0, "@type", { link = "Type" })
  hl.set(0, "@punctuation", { link = "Delimiter" })
end)
