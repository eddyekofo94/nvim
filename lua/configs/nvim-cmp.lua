local cmp = require "cmp"
local cmp_core = require "cmp.core"
local compare = require "cmp.config.compare"
local types = require "cmp.types"
local luasnip = require "luasnip"
local tabout = require "utils.tabout"
local lspkind = require "lspkind"
local utils = require "utils.cmp"
local icons = require("utils.static").icons
local visible_buffers = require("utils.buffer").visible_buffers
local border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" }

local entry_filter_fuzzy_path, fuzzy_path_option, limit_lsp_types, has_words_before, check_backspace =
  utils.fuzzy_path_option,
  utils.entry_filter_fuzzy_path,
  utils.limit_lsp_types,
  utils.has_words_before,
  utils.check_backspace

---Hack: `nvim_lsp` and `nvim_lsp_signature_help` source still use
---deprecated `vim.lsp.buf_get_clients()`, which is slower due to
---the deprecation and version check in that function. Overwrite
---it using `vim.lsp.get_clients()` to improve performance.
---@diagnostic disable-next-line: duplicate-set-field
function vim.lsp.buf_get_clients(bufnr)
  return vim.lsp.get_clients { buffer = bufnr }
end

local termcodes = function(str)
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

---@type string?
local last_key

lspkind.init {
  preset = "codicons",
}

vim.on_key(function(k)
  last_key = k
end)

---@type integer
local last_changed = 0
local _cmp_on_change = cmp_core.on_change

---Improves performance when inserting in large files
---@diagnostic disable-next-line: duplicate-set-field
function cmp_core.on_change(self, trigger_event)
  -- Don't know why but inserting spaces/tabs causes higher latency than other
  -- keys, e.g. when holding down 's' the interval between keystrokes is less
  -- than 32ms (80 repeats/s keyboard), but when holding spaces/tabs the
  -- interval increases to 100ms, guess is is due ot some other plugins that
  -- triggers on spaces/tabs
  -- Spaces/tabs are not useful in triggering completions in insert mode but can
  -- be useful in command-line autocompletion, so ignore them only when not in
  -- command-line mode
  if (last_key == " " or last_key == "\t") and string.sub(vim.fn.mode(), 1, 1) ~= "c" then
    return
  end

  local now = vim.uv.now()
  local fast_typing = now - last_changed < 32
  last_changed = now

  if not fast_typing or trigger_event ~= "TextChanged" or cmp.visible() then
    _cmp_on_change(self, trigger_event)
    return
  end

  vim.defer_fn(function()
    if last_changed == now then
      _cmp_on_change(self, trigger_event)
    end
  end, 200)
end

---Choose the closer destination between two destinations
---@param dest1 number[]?
---@param dest2 number[]?
---@return number[]|nil
local function choose_closer(dest1, dest2)
  if not dest1 then
    return dest2
  end
  if not dest2 then
    return dest1
  end

  local current_pos = vim.api.nvim_win_get_cursor(0)
  local line_width = vim.api.nvim_win_get_width(0)
  local dist1 = math.abs(dest1[2] - current_pos[2]) + math.abs(dest1[1] - current_pos[1]) * line_width
  local dist2 = math.abs(dest2[2] - current_pos[2]) + math.abs(dest2[1] - current_pos[1]) * line_width
  if dist1 <= dist2 then
    return dest1
  else
    return dest2
  end
end

---Check if a node has length larger than 0
---@param node table
---@return boolean
local function node_has_length(node)
  local start_pos, end_pos = node:get_buf_position()
  return start_pos[1] ~= end_pos[1] or start_pos[2] ~= end_pos[2]
end

---Check if range1 contains range2
---If range1 == range2, return true
---@param range1 integer[][] 0-based range
---@param range2 integer[][] 0-based range
---@return boolean
local function range_contains(range1, range2)
  -- stylua: ignore start
  return (
    range2[1][1] > range1[1][1]
    or (range2[1][1] == range1[1][1]
        and range2[1][2] >= range1[1][2])
    )
    and (
      range2[1][1] < range1[2][1]
      or (range2[1][1] == range1[2][1]
          and range2[1][2] <= range1[2][2])
    )
    and (
      range2[2][1] > range1[1][1]
      or (range2[2][1] == range1[1][1]
          and range2[2][2] >= range1[1][2])
    )
    and (
      range2[2][1] < range1[2][1]
      or (range2[2][1] == range1[2][1]
          and range2[2][2] <= range1[2][2])
    )
  -- stylua: ignore end
end

---Check if the cursor position is in the given range
---@param range integer[][] 0-based range
---@param cursor integer[] 1,0-based cursor position
---@return boolean
local function in_range(range, cursor)
  local cursor0 = { cursor[1] - 1, cursor[2] }
  -- stylua: ignore start
  return (
    cursor0[1] > range[1][1]
    or (cursor0[1] == range[1][1]
        and cursor0[2] >= range[1][2])
    )
    and (
      cursor0[1] < range[2][1]
      or (cursor0[1] == range[2][1]
          and cursor0[2] <= range[2][2])
    )
  -- stylua: ignore end
end

---Find the parent (a previous node that contains the current node) of the node
---@param node table current node
---@return table|nil
local function node_find_parent(node)
  local range_start, range_end = node:get_buf_position()
  local prev = node.parent.snippet and node.parent.snippet.prev.prev
  while prev do
    local range_start_prev, range_end_prev = prev:get_buf_position()
    if range_contains({ range_start_prev, range_end_prev }, { range_start, range_end }) then
      return prev
    end
    prev = prev.parent.snippet and prev.parent.snippet.prev.prev
  end
end

---Check if the cursor is at the end of a node
---@param range table 0-based range
---@param cursor number[] 1,0-based cursor position
---@return boolean
local function cursor_at_end_of_range(range, cursor)
  return range[2][1] + 1 == cursor[1] and range[2][2] == cursor[2]
end

---Jump to the closer destination between a snippet and tabout
---@param snip_dest number[]
---@param tabout_dest number[]?
---@param direction number 1 or -1
---@return boolean true if a jump is performed
local function jump_to_closer(snip_dest, tabout_dest, direction)
  direction = direction or 1
  local dest = choose_closer(snip_dest, tabout_dest)
  if not dest then
    return false
  end
  if vim.deep_equal(dest, tabout_dest) then
    tabout.jump(direction)
  else
    luasnip.jump(direction)
  end
  return true
end

---Options for fuzzy_path source
local fuzzy_path_option = {
  fd_cmd = {
    vim.fn.executable "fd" == 1 and "fd" or "fdfind",
    "-p",
    "-H",
    "-L",
    "-td",
    "-tf",
    "-tl",
    "--mount",
    "-c=never",
    "-E=*.git/",
    "-E=*.venv/",
    "-E=*Cache*/",
    "-E=*cache*/",
    "-E=.*Cache*/",
    "-E=.*cache*/",
    "-E=.*wine/",
    "-E=.cargo/",
    "-E=.conda/",
    "-E=.dot/",
    "-E=.fonts/",
    "-E=.ipython/",
    "-E=.java/",
    "-E=.jupyter/",
    "-E=.luarocks/",
    "-E=.mozilla/",
    "-E=.npm/",
    "-E=.nvm/",
    "-E=.steam*/",
    "-E=.thunderbird/",
    "-E=.tmp/",
    "-E=__pycache__/",
    "-E=dosdevices/",
    "-E=node_modules/",
    "-E=vendor/",
    "-E=venv/",
  },
}

local icon_dot = icons.DotLarge
local icon_calc = icons.Calculator
local icon_folder = icons.Folder
local icon_file = icons.File
local compltype_path = {
  dir = true,
  file = true,
  file_in_path = true,
  runtime = true,
}

---@return integer[] buffer numbers
local function get_bufnrs()
  return vim.b.bigfile and {} or { vim.api.nvim_get_current_buf() }
end

local fuzzy_path_ok, fuzzy_path_comparator = pcall(require, "cmp_fuzzy_path.compare")

if not fuzzy_path_ok then
  fuzzy_path_comparator = function() end
end

cmp.setup {
  enabled = function()
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = 0 })
    if buftype == "prompt" or buftype == "acwrite" or vim.b.bigfile then
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
  performance = {
    async_budget = 64,
    max_view_entries = 64,
    fetching_timeout = 250,
  },
  preselect = cmp.PreselectMode.None,
  duplicates_default = 0,
  confirm_opts = {
    behavior = cmp.ConfirmBehavior.Replace,
    select = true,
  },
  duplicates = {
    nvim_lsp = 0,
    luasnip = 1,
    buffer = 1,
    rg = 0,
    path = 1,
  },
  experimental = {
    ghost_text = false,
    git = {
      async = true,
    },
  },
  formatting = {
    fields = { "kind", "abbr", "menu" },
    format = function(entry, cmp_item)
      local kind = lspkind.cmp_format { mode = "symbol_text", maxwidth = 50 }(entry, cmp_item)
      local strings = vim.split(kind.kind, "%s", { trimempty = true })
      kind.kind = " " .. (strings[1] or "") .. " "
      kind.menu = "    [" .. (strings[2] or "") .. "]"

      local compltype = vim.fn.getcmdcompltype()
      local complpath = compltype_path[compltype]

      -- Use special icons for file / directory completions
      if cmp_item.kind == "File" or cmp_item.kind == "Folder" or complpath then
        if string.sub(cmp_item.word, #cmp_item.word) == "/" then -- Directories
          cmp_item.kind = icon_folder
          cmp_item.kind_hl_group = "CmpItemKindFolder"
        else -- Files
          local icon = icon_file
          local icon_hl = "CmpItemKindFile"
          local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
          if devicons_ok then
            icon, icon_hl = devicons.get_icon(
              vim.fs.basename(cmp_item.word),
              vim.fn.fnamemodify(cmp_item.word, ":e"),
              { default = true }
            )
            icon = icon and icon .. " "
          end
          cmp_item.kind = icon or icon_file
          cmp_item.kind_hl_group = icon_hl or "CmpItemKindFile"
        end
        -- else -- Use special icons for some completions
        --   cmp_item.kind = entry.source.name == "cmdline" and icon_dot
        --     or entry.source.name == "calc" and icon_calc
        --     or icons[cmp_item.kind]
        --     or ""
      end
      ---@param field string
      ---@param min_width integer
      ---@param max_width integer
      ---@return nil
      local function clamp(field, min_width, max_width)
        if not cmp_item[field] or not type(cmp_item) == "string" then
          return
        end
        -- In case that min_width > max_width
        if min_width > max_width then
          min_width, max_width = max_width, min_width
        end
        local field_str = cmp_item[field]
        local field_width = vim.fn.strdisplaywidth(field_str)
        if field_width > max_width then
          local former_width = math.floor(max_width * 0.6)
          local latter_width = math.max(0, max_width - former_width - 1)
          cmp_item[field] = string.format("%s…%s", field_str:sub(1, former_width), field_str:sub(-latter_width))
        elseif field_width < min_width then
          cmp_item[field] = string.format("%-" .. min_width .. "s", field_str)
        end
      end
      clamp("abbr", vim.go.pw, math.max(60, math.ceil(vim.o.columns * 0.4)))
      clamp("menu", 0, math.max(16, math.ceil(vim.o.columns * 0.2)))

      -- append source name to menu
      if entry.completion_item.detail ~= nil and entry.completion_item.detail ~= "" then
        kind.menu = kind.menu .. "    (" .. entry.completion_item.detail .. ")"
      end

      return cmp_item
    end,
  },
  matching = {
    disallow_fuzzy_matching = false,
    disallow_fullfuzzy_matching = false,
    disallow_partial_fuzzy_matching = true,
    disallow_partial_matching = false,
    disallow_prefix_unmatching = true,
  },
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = {
    ["<CR>"] = cmp.mapping.confirm {
      i = function(fallback)
        if cmp.visible() and cmp.get_active_entry() then
          cmp.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = false,
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
    ["<S-Tab>"] = {
      ["c"] = function()
        if tabout.get_jump_pos(-1) then
          tabout.jump(-1)
          return
        end
        if cmp.visible() then
          cmp.select_prev_item()
        else
          cmp.complete()
        end
      end,
      ["i"] = function(fallback)
        if luasnip.locally_jumpable(-1) then
          local prev = luasnip.jump_destination(-1)
          local _, snip_dest_end = prev:get_buf_position()
          snip_dest_end[1] = snip_dest_end[1] + 1 -- (1, 0) indexed
          local tabout_dest = tabout.get_jump_pos(-1)
          if not jump_to_closer(snip_dest_end, tabout_dest, -1) then
            fallback()
          end
        else
          fallback()
        end
      end,
    },
    ["<Tab>"] = {
      ["c"] = function()
        if tabout.get_jump_pos(1) then
          tabout.jump(1)
          return
        end
        if cmp.visible() then
          cmp.select_next_item()
        else
          cmp.complete()
        end
      end,
      ["i"] = function(fallback)
        if luasnip.expandable() then
          luasnip.expand()
        elseif luasnip.locally_jumpable(1) then
          local buf = vim.api.nvim_get_current_buf()
          local cursor = vim.api.nvim_win_get_cursor(0)
          local current = luasnip.session.current_nodes[buf]
          if node_has_length(current) then
            if
              current.next_choice
              or cursor_at_end_of_range({
                current:get_buf_position(),
              }, cursor)
            then
              luasnip.jump(1)
            else
              fallback()
            end
          else -- node has zero length
            local parent = node_find_parent(current)
            local range = parent and { parent:get_buf_position() }
            local tabout_dest = tabout.get_jump_pos(1)
            if tabout_dest and range and in_range(range, tabout_dest) then
              tabout.jump(1)
            else
              luasnip.jump(1)
            end
          end
        else
          fallback()
        end
      end,
    },
    ["<C-p>"] = {
      ["c"] = cmp.mapping.select_prev_item(),
      ["i"] = function()
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.choice_active() then
          luasnip.change_choice(-1)
        else
          cmp.complete()
        end
      end,
    },
    ["<C-j>"] = cmp.mapping {
      s = function()
        if cmp.visible() then
          cmp.select_next_item { behavior = cmp.SelectBehavior.Replace }
        else
          vim.api.nvim_feedkeys(termcodes "<Down>", "n", true)
        end
      end,
      c = function()
        if cmp.visible() then
          cmp.select_next_item { behavior = cmp.SelectBehavior.Replace }
        else
          vim.api.nvim_feedkeys(termcodes "<Down>", "n", true)
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
        else
          vim.api.nvim_feedkeys(termcodes "<Up>", "n", true)
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
    ["<C-n>"] = {
      ["c"] = cmp.mapping.select_next_item(),
      ["i"] = function()
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.choice_active() then
          luasnip.change_choice(1)
        else
          cmp.complete()
        end
      end,
    },
    ["<Down>"] = cmp.mapping(cmp.mapping.select_next_item(), { "i", "c" }),
    ["<Up>"] = cmp.mapping(cmp.mapping.select_prev_item(), { "i", "c" }),
    ["<PageDown>"] = cmp.mapping(
      cmp.mapping.select_next_item {
        count = vim.o.pumheight ~= 0 and math.ceil(vim.o.pumheight / 2) or 8,
      },
      { "i", "c" }
    ),
    ["<PageUp>"] = cmp.mapping(
      cmp.mapping.select_prev_item {
        count = vim.o.pumheight ~= 0 and math.ceil(vim.o.pumheight / 2) or 8,
      },
      { "i", "c" }
    ),
    ["<C-u>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
    ["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
    ["<C-e>"] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.abort()
      else
        fallback()
      end
    end, { "i", "c" }),
    ["<C-y>"] = cmp.mapping(
      cmp.mapping.confirm {
        behavior = cmp.ConfirmBehavior.Replace,
        select = false,
      },
      { "i", "c" }
    ),
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
  },
  sources = {
    {
      name = "luasnip",
      keyword_length = 2,
      max_item_count = 3,
      dup = 0,
      option = {
        use_show_condition = true,
        show_autosnippets = true,
      },
      entry_filter = function()
        local context = require "cmp.config.context"
        return not context.in_treesitter_capture "string" and not context.in_syntax_group "String"
      end,
    },
    { name = "nvim_lua" },
    {
      name = "treesitter",
      keyword_length = 4,
      max_item_count = 5,
    },
    { name = "nvim_lsp_signature_help" },
    { name = "nvim_lsp", max_item_count = 20 },
    {
      name = "buffer",
      max_item_count = 3,
      keyword_length = 3,
      dup = 0,
      option = {
        get_bufnrs = visible_buffers, -- Suggest words from all visible buffers
      },
    },
    -- {
    --   name = "buffer",
    --   max_item_count = 8,
    --   option = {
    --     get_bufnrs = get_bufnrs,
    --   },
    -- },
    {
      name = "fuzzy_path",
      option = fuzzy_path_option,
      -- Don't show fuzzy-path entries in markdown/tex mathzone
      entry_filter = function()
        return vim.g.loaded_vimtex ~= 1
          or vim.bo.ft ~= "markdown" and vim.bo.ft ~= "tex"
          or vim.api.nvim_eval "vimtex#syntax#in_mathzone()" ~= 1
      end,
    },
    { name = "calc" },
  },
  sorting = {
    priority_weight = 2,
    ---@type table[]|function[]
    comparators = {
      cmp.config.compare.locality,
      function(entry1, entry2) -- sort by length ignoring "=~"
        local len1 = string.len(string.gsub(entry1.completion_item.label, "[=~()]", ""))
        local len2 = string.len(string.gsub(entry2.completion_item.label, "[=~()]", ""))
        if len1 ~= len2 then
          return len1 - len2 < 0
        end
      end,
      function(entry1, entry2) -- score by lsp, if available
        local t1 = entry1.completion_item.sortText
        local t2 = entry2.completion_item.sortText
        if t1 ~= nil and t2 ~= nil and t1 ~= t2 then
          return t1 < t2
        end
      end,
      compare.kind,
      compare.scopes,
      compare.offset,
      function(entry1, entry2) -- sort by compare kind (Variable, Function etc)
        local kind1 = modified_kind(entry1:get_kind())
        local kind2 = modified_kind(entry2:get_kind())
        if kind1 ~= kind2 then
          return kind1 - kind2 < 0
        end
      end,
      compare.sort_text,
      compare.recently_used,
      fuzzy_path_comparator,
      cmp.config.compare.exact,
      cmp.config.compare.score,
    },
  },
  completion = {
    completeopt = "menu,menuone,noinsert",
    autocomplete = { types.cmp.TriggerEvent.TextChanged },
    keyword_length = 1,
  },
  -- cmp floating window config
  window = {
    completion = cmp.config.window.bordered {
      border = border,
      winhighlight = "CmpPmenu:FloatBorder,CursorLine:CmpSel,Search:None",
      col_offset = -3,
      side_padding = 0,
      scrolloff = vim.go.scrolloff,
    },
    documentation = cmp.config.window.bordered {
      border = border,
      winhighlight = "CmpPmenu:FloatBorder,CursorLine:CmpSel,Search:None",
      max_width = 80,
      max_height = 20,
      -- border = "solid",
    },
  },
}

-- Use buffer source for `/`.
cmp.setup.cmdline("/", {
  enabled = true,
  sources = {
    {
      name = "buffer",
      option = {
        get_bufnrs = get_bufnrs,
      },
    },
  },
})
cmp.setup.cmdline("?", {
  enabled = true,
  sources = {
    {
      name = "buffer",
      option = {
        get_bufnrs = get_bufnrs,
      },
    },
  },
})

-- Use cmdline & path source for ':'.
cmp.setup.cmdline(":", {
  enabled = true,
  sources = {
    {
      name = "fuzzy_path",
      group_index = 1,
      option = fuzzy_path_option,
    },
    {
      name = "cmdline",
      option = {
        ignore_cmds = {},
      },
      group_index = 2,
    },
    { name = "cmdline_history", max_item_count = 10 },
  },
})

cmp.setup.filetype({ "NeogitCommitMessage", "TelescopePrompt" }, {
  sources = {},
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
