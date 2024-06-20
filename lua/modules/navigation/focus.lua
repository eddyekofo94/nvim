local function config()
  local maps = require("utils").keymaps:empty_map_table()
  local keymap_utils = require "utils.keymaps"
  local map = keymap_utils.set_n_keymap
  local focus = require "focus"

  local ignore_filetypes = {
    "undotree_2",
    "diffpanel_3",
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
    ui = {
      absolutenumber_unfocussed = true,
      number = false, -- Display line numbers in the focussed window only
      relativenumber = false, -- Display relative line numbers in the focussed window only
      hybridnumber = false, -- Display hybrid line numbers in the focussed window only
      signcolumn = true, -- Display signcolumn in the focussed window only
      cursorline = true, -- Display a cursorline in the focussed window only
    },
  }

  maps.n["<C-\\>"] = {
    "<cmd>FocusAutoresize<cr>",
    desc = "Activate autoresise",
  }
  maps.n["<leader>ww"] = {
    "<cmd>FocusMaxOrEqual<cr>",
    desc = "Max window",
  }

  maps.n["<leader>tn"] = {
    "<cmd>FocusSplitNicely cmd term<cr>",
    desc = "Terminal Nicely",
  }

  maps.n["<leader>vd"] = {
    "<cmd>FocusSplitDown<CR>",
    desc = "split horizontally",
  }
  -- maps.n["<leader>="] = {
  --   "<cmd>FocusEqualise<CR>",
  --   desc = "balance windows",
  -- }
  -- local ignore_filetypes = { "telescope", "harpoon" }

  map("<leader>=", function()
    focus.focus_equalise()
  end, "balance windows")

  map("<leader>vr", "<cmd>FocusSplitRight<cr>", "Split right")

  map("<leader>vv", function()
    focus.split_nicely()
  end, "Split nicely")

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
end

return {
  "beauwilliams/focus.nvim",
  enabled = true,
  event = "VimEnter",
  cmd = {
    "FocusAutoresize",
  },
  config = config,
}
