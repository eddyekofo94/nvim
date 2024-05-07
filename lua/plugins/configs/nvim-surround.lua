local keymap = require("utils.keymaps").set_keymap
local augroup = "Surround"

keymap("n", "ysS", "s$", { remap = true, desc = "Surround until end of line" })

local function filetype_surround(filetype, surrounds)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = filetype,
    callback = function()
      require("nvim-surround").buffer_setup {
        surrounds = surrounds,
      }
    end,
    group = augroup,
  })
end

vim.api.nvim_create_augroup(augroup, {})

filetype_surround("lua", {
  F = {
    -- Anonymous function
    add = function()
      return { { "function() return " }, { " end" } }
    end,
  },
})
filetype_surround("markdown", {
  c = {
    -- Code block
    add = function()
      return { { "```", "" }, { "", "```" } }
    end,
  },
})
filetype_surround({ "rust", "typescript" }, {
  T = {
    -- Type
    add = function()
      return {
        { vim.fn.input { prompt = "Type name: " } .. "<" },
        { ">" },
      }
    end,
  },
})
filetype_surround({ "typescript" }, {
  s = {
    -- String interpolation
    add = function()
      return { { "${" }, { "}" } }
    end,
  },
})
require("nvim-surround").setup {
  move_cursor = true,
  keymaps = {
    normal = "ys",
    normal_cur = "yss",
    visual = "ys",
    visual_line = "yS",
  },
  aliases = {
    c = "{",
    b = "(",
    s = "[",
    q = '"',
    Q = "'",
    A = "`",
  },
}
