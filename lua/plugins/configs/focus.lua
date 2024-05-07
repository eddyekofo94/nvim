local maps = require("utils").keymaps:empty_map_table()
local keymap_utils = require("utils.keymaps")

local ignore_filetypes = {
  "prompt",
  "NvimTree",
  "bmessages_buffer",
  "nvim-tree",
  "qf",
  "git-conflict",
  "dap-repl",
  "dapui_scopes",
  "dapui_stacks",
  "dapui_breakpoints",
  "dapui_console",
  "dapui_watches",
  "dapui_repl",
  "undotree",
  "noice",
  "man",
  "messages",
  "undotree",
  "NeogitStatus",
  "notify",
  "Trouble",
  "diffview",
  "diffview*",
  "oil",
  "telescope",
  "toggleterm",
  "lazy",
  "Outline",
  "TelescopePrompt",
  "TelescopeResults",
  "TelescopePreview",
  "DiffviewFilePanel",
  "Diffview*",
}

local opts = {
  autoresize = {
    enable = true,
    quickfixheight = 60,
  },
  signcolumn = true,
  excluded_buftypes = ignore_filetypes,
  excluded_filetypes = ignore_filetypes,
  compatible_filetrees = { "git-conflict" },
  --  INFO: 2023-09-13 - Moved to autocommands
  ui = {
    number = false,         -- Display line numbers in the focussed window only
    relativenumber = false, -- Display relative line numbers in the focussed window only
    hybridnumber = false,   -- Display hybrid line numbers in the focussed window only
    winhighlight = false,   -- Auto highlighting for focussed/unfocussed windows
    cursorline = true,      -- Display a cursorline in the focussed window only
  },
}

-- M.focus = {
--   {
--     "<leader>vj",
--     "<cmd>FocusSplitDown<cr>",
--     desc = "Split Down",
--   },
--   {
--     "<leader>ve",
--     "<cmd>FocusEnable<cr>",
--     desc = "Focus Enable",
--   },
--   {
--     "<leader>vh",
--     "<cmd>FocusSplitLeft<cr>",
--     desc = "Split Left",
--   },
--   {
--     "<leader>vt",
--     "<cmd>FocusToggle<cr>",
--     desc = "Focus Toggle",
--   },
--   {
--     "<leader>vl",
--     "<cmd>FocusSplitRight<cr>",
--     desc = "Split Right",
--   },
--   {
--     "<C-w>",
--     "<cmd>FocusSplitCycle<cr>",
--     desc = "Move next buffer",
--   },
--   {
--     "<leader>vk",
--     "<cmd>FocusSplitUp<cr>",
--     desc = "Split Right",
--   },
--   {
--     "<leader>vv",
--     "<cmd>FocusSplitNicely<cr>",
--     desc = "Split Nicely",
--   },
--   {
--     "<leader>ww",
--     "<cmd>FocusMaxOrEqual<cr>",
--     desc = "Max window",
--   },
--   {
--     "<leader>-",
--     "<cmd>FocusSplitDown<CR>",
--     desc = "split horizontally",
--   },
--   {
--     "<leader>=",
--     "<cmd>FocusEqualise<CR>",
--     desc = "balance windows",
--   },
-- }

maps.n["<leader>vv"] = {
  "<cmd>FocusSplitNicely<cr>",
  desc = "Split Nicely",
}

maps.n["<C-\\>"] = {
  "<cmd>FocusAutoresize<cr>",
  desc = "Activate autoresise",
}
maps.n["<leader>ww"] = {
  "<cmd>FocusMaxOrEqual<cr>",
  desc = "Max window",
}

maps.n["<leader>vr"] = {
  "<cmd>FocusSplitRight<cr>",
  desc = "Split Right",
}

maps.n["<leader>tn"] = {
  "<cmd>FocusSplitNicely cmd term<cr>",
  desc = "Terminal Nicely",
}

maps.n["<leader>vd"] = {
  "<cmd>FocusSplitDown<CR>",
  desc = "split horizontally",
}
maps.n["<leader>="] = {
  "<cmd>FocusEqualise<CR>",
  desc = "balance windows",
}
-- local ignore_filetypes = { "telescope", "harpoon" }

local augroup = vim.api.nvim_create_augroup("FocusDisable", { clear = true })

vim.api.nvim_create_autocmd("WinEnter", {
  group = augroup,
  callback = function(_)
    if vim.tbl_contains(ignore_filetypes, vim.bo.buftype) then
      vim.b.focus_disable = true
    end
  end,
  desc = "Disable focus autoresize for BufType",
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  callback = function(_)
    if vim.tbl_contains(ignore_filetypes, vim.bo.filetype) then
      vim.b.focus_disable = true
    end
  end,
  desc = "Disable focus autoresize for FileType",
})

require("focus").setup(opts)
keymap_utils.set_mappings(maps)
