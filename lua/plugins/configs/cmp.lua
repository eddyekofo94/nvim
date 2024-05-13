local cmp = require "cmp"
local types = require "cmp.types"
local compare = require "cmp.config.compare"
local luasnip = require "luasnip"
local lspkind = require "lspkind"
local visible_buffers = require("utils.buffer").visible_buffers
local utils_cmp = require "utils.cmp"
local entry_filter_fuzzy_path, fuzzy_path_option, limit_lsp_types, has_words_before, check_backspace =
  utils_cmp.fuzzy_path_option, utils_cmp.entry_filter_fuzzy_path, utils_cmp.limit_lsp_types, utils_cmp.has_words_before, utils_cmp.check_backspace

local fuzzy_path_ok, fuzzy_path_comparator = pcall(require, "cmp_fuzzy_path.compare")

if not fuzzy_path_ok then
  fuzzy_path_comparator = function() end
end

local border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" }

lspkind.init {
  preset = "codicons",
}

local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

---@type table<integer, integer>
local modified_priority = {
  [types.lsp.CompletionItemKind.Variable] = 1,
  [types.lsp.CompletionItemKind.Constant] = 1,
  [types.lsp.CompletionItemKind.Keyword] = 1, -- top
  [types.lsp.CompletionItemKind.Snippet] = 2,
  [types.lsp.CompletionItemKind.Function] = types.lsp.CompletionItemKind.Method,
  [types.lsp.CompletionItemKind.Text] = 100, -- bottom
}

---@param kind integer: kind of completion entry
local function modified_kind(kind)
  return modified_priority[kind] or kind
end

cmp.setup {
  enabled = function()
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = 0 })
    if buftype == "prompt" or buftype == "acwrite" then
      return false
    end

    -- disable completion in comments
    local context = require "cmp.config.context"
    -- keep command mode completion enabled when cursor is in a comment.
    if vim.api.nvim_get_mode().mode == "c" then
      return true
    else
      return not context.in_treesitter_capture "comment" and not context.in_syntax_group "Comment"
    end
  end,
  completion = {
    -- completeopt = "menu,menuone,insert", -- INFO: I like this option
    completeopt = "menu,menuone,noinsert,preview",
    autocomplete = { types.cmp.TriggerEvent.TextChanged },
    keyword_length = 2,
  },
  -- explanations: https://github.com/hrsh7th/nvim-cmp/blob/main/doc/cmp.txt#L425
  performance = {
    debounce = 30,
    throttle = 20,
    async_budget = 0.8,
    max_view_entries = 10,
    fetching_timeout = 250,
  },
  preselect = cmp.PreselectMode.None,
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
      -- vim.snippet.expand(args.body)
    end,
  },
  matching = {
    disallow_fuzzy_matching = false,
    disallow_fullfuzzy_matching = false,
    disallow_partial_fuzzy_matching = true,
    disallow_partial_matching = false,
    disallow_prefix_unmatching = true,
  },
  duplicates = {
    nvim_lsp = 0,
    luasnip = 1,
    buffer = 1,
    rg = 0,
    path = 1,
  },
  duplicates_default = 0,
  confirm_opts = {
    behavior = cmp.ConfirmBehavior.Replace,
    select = true,
  },
  mapping = {
    ["<C-u>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
    ["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
    ["<c-q>"] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = false,
    },
    ["<C-Space>"] = cmp.mapping {
      i = cmp.mapping.complete(),
      c = function(_)
        if cmp.visible() then
          if not cmp.confirm { select = true } then
            return
          end
        else
          cmp.complete()
        end
      end,
    },
    ["<C-e>"] = cmp.mapping.close(),
    ["<CR>"] = cmp.mapping.confirm {
      i = function(fallback)
        if cmp.visible() and cmp.get_active_entry() then
          cmp.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }
        else
          fallback()
        end
      end,
      c = function(fallback)
        if cmp.visible() then
          cmp.confirm { behavior = cmp.ConfirmBehavior.Replace, select = true }
        else
          fallback()
        end
      end,
      s = function(fallback)
        if cmp.visible() then
          cmp.confirm { behavior = cmp.ConfirmBehavior.Replace, select = true }
        else
          fallback()
        end
      end,
      -- s = cmp.mapping { select = true },
    },
    ["<C-j>"] = cmp.mapping {
      s = function()
        if cmp.visible() then
          cmp.select_next_item { behavior = cmp.SelectBehavior.Replace }
        else
          vim.api.nvim_feedkeys(t "<Down>", "n", true)
        end
      end,
      c = function()
        if cmp.visible() then
          cmp.select_next_item { behavior = cmp.SelectBehavior.Replace }
        else
          vim.api.nvim_feedkeys(t "<Down>", "n", true)
        end
      end,
      i = function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif check_backspace() then
          fallback()
        else
          fallback()
        end
      end,
    },
    ["<C-k>"] = cmp.mapping {
      c = function()
        if cmp.visible() then
          cmp.select_prev_item { behavior = cmp.SelectBehavior.Replace }
          -- cmp.select_prev_item()
        else
          vim.api.nvim_feedkeys(t "<Up>", "n", true)
        end
      end,
      i = function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        else
          fallback()
        end
      end,
    },
    ["<Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item { behavior = cmp.SelectBehavior.Insert }
      elseif cmp.visible() and has_words_before() then
        cmp.select_next_item { behavior = cmp.SelectBehavior.Select }
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      elseif has_words_before() then
        cmp.complete()
      elseif check_backspace() then
        fallback()
      else
        fallback()
      end
    end, {
      "i",
      "s",
    }),
    ["<S-Tab>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item { behavior = cmp.SelectBehavior.Insert }
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, {
      "i",
      "s",
    }),
    ["<C-c>"] = cmp.mapping {
      i = function(fallback)
        if cmp.visible() then
          cmp.abort()
        else
          fallback()
        end
      end,
      c = function(fallback)
        if cmp.visible() then
          cmp.close()
        else
          fallback()
        end
      end,
    },
  },
  sources = {
    {
      name = "nvim_lsp",
      priority_weight = 85,
      max_item_count = 50,
      keyword_length = 1,
      -- Limits LSP results to specific types based on line context (Fields, Methods, Variables)
      entry_filter = limit_lsp_types,
    },
    {
      name = "luasnip",
      keyword_length = 2,
      max_item_count = 3,
      option = {
        use_show_condition = true,
        show_autosnippets = true,
      },
      entry_filter = function()
        local context = require "cmp.config.context"
        return not context.in_treesitter_capture "string" and not context.in_syntax_group "String"
      end,
    },
    { name = "nvim_lsp_signature_help" },
    { name = "nvim_lua" },
    {
      name = "treesitter",
      keyword_length = 4,
      max_item_count = 5,
    },
    { name = "neorg" },
    { name = "path", priority_weight = 100, max_item_count = 40 },
    {
      name = "fuzzy_path",
      option = { fd_timeout_msec = 1500 },
      -- entry_filter = entry_filter_fuzzy_path,
      -- option = fuzzy_path_option,
    },
    {
      name = "buffer",
      max_item_count = 3,
      keyword_length = 3,
      dup = 0,
      option = {
        get_bufnrs = visible_buffers, -- Suggest words from all visible buffers
      },
    },
    {
      name = "rg",
      priority_weight = 60,
      max_item_count = 10,
      keyword_length = 4,
      option = {
        additional_arguments = "--smart-case",
      },
    },
    { name = "calc" },
  },
  view = {
    entries = { name = "custom", selection_order = "near_cursor" },
    docs = {
      auto_open = false,
    },
  },
  window = {
    completion = cmp.config.window.bordered {
      border = border,
      -- winhighlight = "FloatBorder:CmpBorder,Normal:CmpPmenu,CursorLine:CmpSel,Search:None",
      col_offset = -3,
      side_padding = 0,
    },
    documentation = cmp.config.window.bordered {
      border = border,
      -- winhighlight = "Normal:Normal,FloatBorder:CmpBorder,CursorLine:Visual,Search:None",
      winhighlight = "FloatBorder:CmpBorder,Normal:CmpDoc",
      side_padding = 1,
    },
  },
  sorting = {
    priority_weight = 2,
    comparators = {
      compare.recently_used,
      compare.exact,
      function(entry1, entry2) -- sort by compare kind (Variable, Function etc)
        local kind1 = modified_kind(entry1:get_kind())
        local kind2 = modified_kind(entry2:get_kind())
        if kind1 ~= kind2 then
          return kind1 - kind2 < 0
        end
      end,
      compare.locality,
      function(entry1, entry2) -- sort by length ignoring "=~"
        local len1 = string.len(string.gsub(entry1.completion_item.label, "[=~()]", ""))
        local len2 = string.len(string.gsub(entry2.completion_item.label, "[=~()]", ""))
        if len1 ~= len2 then
          return len1 - len2 < 0
        end
      end,
      compare.scopes,
      function(entry1, entry2) -- score by lsp, if available
        local t1 = entry1.completion_item.sortText
        local t2 = entry2.completion_item.sortText
        if t1 ~= nil and t2 ~= nil and t1 ~= t2 then
          return t1 < t2
        end
      end,
      compare.sort_text,
      compare.order,
      fuzzy_path_comparator,
    },
  },
  experimental = {
    native_menu = false,
    ghost_text = false,
    git = {
      async = true,
    },
  },
  formatting = {
    fields = { "kind", "abbr", "menu" },
    format = function(entry, vim_item)
      local kind = lspkind.cmp_format { mode = "symbol_text", maxwidth = 50 }(entry, vim_item)

      local strings = vim.split(kind.kind, "%s", { trimempty = true })

      kind.kind = " " .. (strings[1] or "") .. " "
      kind.menu = "    (" .. (strings[2] or "") .. ")"
      return kind
    end,
  },
}

cmp.setup.filetype({ "NeogitCommitMessage", "TelescopePrompt" }, {
  sources = {},
})

-- Set configuration for specific filetype.
-- You can specify the `git` source if [you were installed it](https://github.com/petertriho/cmp-git).
cmp.setup.filetype("gitcommit", {
  sources = cmp.config.sources({
    { name = "git" },
  }, {
    { name = "buffer" },
  }),
})

cmp.setup.filetype({ "oil" }, {
  enabled = true,
  sources = {
    {
      name = "rg",
      priority_weight = 60,
      max_item_count = 10,
      keyword_length = 5,
      option = {
        additional_arguments = "--smart-case",
      },
    },
    {
      name = "spell",
      keyword_length = 3,
      priority = 5,
      keyword_pattern = [[\w\+]],
    },
  },
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ "/", "?" }, {
  enabled = true,
  mapping = cmp.mapping.preset.cmdline(),
  sources = {
    { name = "nvim_lsp_document_symbol" },
    { name = "buffer" },
  },
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(":", {
  mapping = cmp.mapping.preset.cmdline(),
  enabled = true,
  sources = cmp.config.sources {
    { name = "cmdline_history", max_item_count = 10 },
    {
      name = "fuzzy_path",
      group_index = 1,
      -- entry_filter = entry_filter_fuzzy_path,
      option = { fd_timeout_msec = 1500 },
      -- option = fuzzy_path_option,
    },
    {
      name = "cmdline",
      option = {
        ignore_cmds = {},
      },
      max_item_count = 30,
      group_index = 2,
    },
    { name = "path", max_item_count = 20 },
  },
})

-- Complete vim.ui.input()
cmp.setup.cmdline("@", {
  enabled = true,
  sources = {
    {
      name = "fuzzy_path",
      group_index = 1,
      -- entry_filter = entry_filter_fuzzy_path,
      -- option = fuzzy_path_option,
    },
    {
      name = "cmdline",
      group_index = 2,
      option = {
        ignore_cmds = {},
      },
    },
    {
      name = "buffer",
      group_index = 3,
      option = {
        get_bufnrs = visible_buffers,
      },
    },
  },
})

-- cmp does not work with cmdline with type other than `:`, '/', and '?', e.g.
-- it does not respect the completion option of `input()`/`vim.ui.input()`, see
-- https://github.com/hrsh7th/nvim-cmp/issues/1690
-- https://github.com/hrsh7th/nvim-cmp/discussions/1073
cmp.setup.cmdline("@", { enabled = false })
cmp.setup.cmdline(">", { enabled = false })
cmp.setup.cmdline("-", { enabled = false })
cmp.setup.cmdline("=", { enabled = false })

-- Completion in DAP buffers
cmp.setup.filetype({ "dap-repl", "dapui_watches", "dapui_hover" }, {
  enabled = true,
  sources = {
    { name = "dap" },
  },
})
