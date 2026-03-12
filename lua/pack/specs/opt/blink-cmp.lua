---@type pack.spec
return {
  src = "https://github.com/saghen/blink.cmp",
  data = {
    optional = vim.g.vscode,
    deps = {
      {
        src = "https://github.com/niuiic/blink-cmp-rg.nvim",
        data = { optional = true },
      },
      {
        src = "https://github.com/L3MON4D3/LuaSnip",
        data = { optional = true },
      },
      {
        src = "https://github.com/kyazdani42/nvim-web-devicons",
        data = { optional = true },
      },
    },
    -- https://github.com/Saghen/blink.cmp/issues/145#issuecomment-2483686337
    -- https://github.com/Saghen/blink.cmp/issues/145#issuecomment-2492759016
    build = string.format(
      "%s cargo build --release",
      vim.env.TERMUX_VERSION
          and 'RUSTC_BOOTSTRAP=1 RUSTFLAGS="-C link-args=-lluajit"'
        or ""
    ),
    events = { "InsertEnter", "CmdlineEnter" },
    postload = function()
      local icons = require "utils.static.icons"
      local has_ls, ls = pcall(require, "luasnip")
      local has_devicons, devicons = pcall(require, "nvim-web-devicons")
      local blink_source_utils = require "blink.cmp.sources.lib.utils"
      local blink_ctx = require "blink.cmp.completion.trigger.context"

      ---@param ctx blink.cmp.DrawItemContext
      ---@return boolean
      local function is_file_compl(ctx)
        return ctx.source_id == "path"
          -- Opencode has slash commands (starting with `/`) and file references,
          -- both provided by the 'opencode_mentions' source. Show file icons only
          -- for file require.
          or ctx.source_id == "opencode_mentions" and not vim.startswith(
            ctx.label,
            "/"
          )
          or vim.tbl_contains(
            { "dir", "file", "file_in_path", "runtime" },
            blink_source_utils.get_completion_type(blink_ctx.get_mode())
          )
      end

      ---@param items blink.cmp.CompletionItem[]
      ---@return boolean
      local function is_expr_compl(items)
        return items[1] and items[1].source_id == "cmdline"
          or vim.tbl_contains(
            { "function", "expression" },
            blink_source_utils.get_completion_type(blink_ctx.get_mode())
          )
      end

      ---@param path string
      ---@return boolean
      local function is_directory(path)
        return vim.endswith(path, "/") or vim.fn.isdirectory(path) == 1
      end

      require("blink.cmp").setup {
        enabled = function()
          return vim.fn.reg_recording() == "" and vim.fn.reg_executing() == ""
        end,
        fuzzy = {
          -- Don't error when rust fuzzy lib is unavailable
          implementation = pcall(require, "blink.cmp.fuzzy.rust")
              and "prefer_rust"
            or "lua",
          sorts = {
            "score", -- Primary sort: by fuzzy matching score
            "sort_text", -- Secondary sort: by sortText field if scores are equal
            "label", -- Tertiary sort: by label if still tied
          },
        },
        completion = {
          list = {
            selection = {
              preselect = false,
              auto_insert = true,
            },
          },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 0,
            treesitter_highlighting = true,
            window = {
              border = "solid",
            },
          },
          menu = {
            min_width = vim.go.pumwidth > 0 and vim.go.pumwidth or nil, ---@diagnostic disable-line: assign-type-mismatch
            max_height = vim.go.pumheight > 0 and vim.go.pumheight or nil, ---@diagnostic disable-line: assign-type-mismatch
            scrolloff = 2,
            draw = {
              columns = {
                { "kind_icon" },
                { "label", "kind", "source_name", gap = 1 },
              },
              -- columns = not vim.g.has_nf and {
              --   { 'label' },
              --   { 'kind_icon' },
              --   { 'label_description' },
              -- } or nil,
              components = {
                label_description = { width = { fill = true } },
                kind = {
                  width = { fill = true },
                  text = function(ctx)
                    return "" .. ctx.kind .. ""
                  end,
                },
                source_name = {
                  width = { fill = true },
                  text = function(ctx)
                    return "[" .. ctx.source_name .. "]"
                  end,
                },
                kind_icon = {
                  ellipsis = false,
                  -- Show different icons for files/directories, use
                  -- nvim-web-devicons to show filetype icons if possible
                  text = function(ctx)
                    if not is_file_compl(ctx) then
                      return icons[ctx.kind] --[[@as string]]
                    end

                    if is_directory(ctx.item.label) then
                      return icons.Folder
                    end

                    return has_devicons
                        and (devicons.get_icon(
                          ctx.item.label,
                          vim.fn.fnamemodify(ctx.item.label, ":e"),
                          { default = true }
                        ))
                      or icons.File
                  end,
                  highlight = function(ctx)
                    if not is_file_compl(ctx) then
                      return ctx.kind_hl
                    end

                    if is_directory(ctx.item.label) then
                      return "BlinkCmpKindFolder"
                    end

                    return has_devicons
                        and ({
                          devicons.get_icon(
                            ctx.item.label,
                            vim.fn.fnamemodify(ctx.item.label, ":e"),
                            { default = true }
                          ),
                        })[2]
                      or "BlinkCmpKindFile"
                  end,
                },
              },
            },
          },
        },
        ---@type table<string, (blink.cmp.KeymapCommand|fun(cmp: blink.cmp.API): boolean?)[]|false>
        keymap = {
          ["<C-u>"] = { "scroll_documentation_up", "fallback" },
          ["<C-d>"] = { "scroll_documentation_down", "fallback" },
          ["<C-p>"] = {
            "select_prev",
            function(cmp)
              if not has_ls or not ls.choice_active() then
                return cmp.show()
              end
            end,
            "fallback", -- change luasnip choice node, see `lua/configs/luasnip.lua`
          },
          ["<C-n>"] = {
            "select_next",
            function(cmp)
              if not has_ls or not ls.choice_active() then
                return cmp.show()
              end
            end,
            "fallback",
          },
          -- Managed by snippet config and tabout plugin, see
          -- - `lua/configs/luasnip.lua`
          -- - `lua/plugin/tabout.lua`
          ["<Tab>"] = false,
          ["<S-Tab>"] = false,
          -- Conflict with readline's keymap, see `lua/plugin/readline.lua`
          ["<C-k>"] = false,
          ["<C-s>"] = { "show_signature", "fallback" },
          ["<CR>"] = { "select_and_accept", "fallback" },
          ["<C-space>"] = { "show", "show_documentation", "hide", "fallback" },
          -- Hide both signature help and completion menu with `<C-e>`
          ["<C-e>"] = {
            function(cmp)
              local hide_success = cmp.hide()
              local hide_signature_success = cmp.hide_signature()
              return hide_success or hide_signature_success
            end,
            "fallback",
          },
        },
        signature = {
          enabled = true,
        },
        snippets = {
          preset = has_ls and "luasnip" or "default",
        },
        cmdline = {
          keymap = {
            preset = "default",
            ["<C-space>"] = {
              "show",
              "show_documentation",
              "hide",
              "fallback",
            },
            -- Recommended: Add a secondary trigger just in case your terminal
            -- is swallowing C-space
            ["<C-@>"] = { "show", "hide", "fallback" }, -- <C-@> is often what <C-space> sends
            ["<C-y>"] = {
              "select_and_accept",
            },
            ["<C-e>"] = { "hide", "fallback" },
            ["<Tab>"] = {
              "show",
              "select_next",
              "snippet_forward",
              "fallback",
            },
            ["<CR>"] = { "select_accept_and_enter", "fallback" },
            ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
            ["<Down>"] = { "select_next", "fallback" },
            ["<Up>"] = { "select_prev", "fallback" },
            ["<C-j>"] = { "select_next", "fallback" },
            ["<C-k>"] = { "select_prev", "fallback" },
            ["<C-h>"] = { "scroll_documentation_down", "fallback" },
            ["<C-l>"] = { "scroll_documentation_up", "fallback" },
          },
          sources = function()
            local type = vim.fn.getcmdtype()
            if type == "/" or type == "?" then
              return { "buffer" }
            else
              return { "cmdline", "path" }
            end
          end,
          completion = {
            list = {
              selection = {
                preselect = false,
                auto_insert = true,
              },
            },
            menu = { auto_show = true },
          },
        },
        sources = {
          default = {
            "snippets",
            "lsp",
            "lazydev",
            "path",
            "buffer",
            "ripgrep",
          },
          min_keyword_length = 0,
          providers = {
            lsp = {
              -- Don't wait for LSP completions for a long time before fallback to
              -- buffer completions
              -- - https://github.com/Saghen/blink.cmp/issues/2042
              -- - https://cmp.saghen.dev/configuration/sources.html#show-buffer-completions-with-lsp
              timeout_ms = 500,
            },
            cmdline = {
              -- Don't complete left parenthesis when calling functions or
              -- expressions in cmdline, e.g. `:call func(...`
              transform_items = function(_, items)
                if not is_expr_compl(items) then
                  return items
                end

                for _, item in ipairs(items) do
                  item.textEdit.newText = item.textEdit.newText:gsub("%($", "")
                  item.label = item.textEdit.newText
                end
                return items
              end,
            },
            ripgrep = {
              module = "blink-cmp-rg",
              name = "Ripgrep",
              score_offset = -10, -- Negative value pulls it to the bottom
              opts = {
                prefix_min_len = 4,
                get_command = function(_, prefix)
                  return {
                    "rg",
                    "--no-config",
                    "--json",
                    "--word-regexp",
                    "--ignore-case",
                    "--",
                    prefix .. "[\\w_-]+",
                    vim.fs.root(0, ".git") or vim.fn.getcwd(),
                  }
                end,
                get_prefix = function(context)
                  return context.line
                    :sub(1, context.cursor[2])
                    :match "[%w_-]+$" or ""
                end,
              },
            },
            lazydev = {
              name = "LazyDev",
              module = "lazydev.integrations.blink",
              score_offset = 100,
              fallbacks = { "lsp" },
            },
            go_pkgs = {
              module = "blink-go-import",
              name = "Import",
            },
            buffer = {
              name = "Buffer",
              module = "blink.cmp.sources.buffer",
              opts = {
                get_bufnrs = function()
                  return vim
                    .iter(vim.api.nvim_list_wins())
                    :map(function(win)
                      return vim.api.nvim_win_get_buf(win)
                    end)
                    :totable()
                end,
              },
            },
            path = {
              opts = {
                get_cwd = function(_)
                  return vim.fn.getcwd()
                end,
              },
            },
          },
        },
      }

      require("utils.hl").persist(function()
        -- stylua: ignore start
        vim.api.nvim_set_hl(0, 'BlinkCmpKindClass',       { link = '@type',               default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindConstant',    { link = '@constant',           default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindConstructor', { link = '@constructor',        default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindEnum',        { link = '@constant',           default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindEnumMember',  { link = '@constant',           default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindFile',        { link = 'Special',             default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindFolder',      { link = 'Directory',           default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindFunction',    { link = '@function',           default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindInterface',   { link = '@type',               default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindKey',         { link = '@keyword',            default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindKeyword',     { link = '@keyword',            default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindMethod',      { link = '@function',           default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindModule',      { link = '@module',             default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindOperator',    { link = '@operator',           default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindProperty',    { link = '@attribute',          default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindSnippet',     { link = '@diff.plus',          default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindString',      { link = '@string',             default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindStruct',      { link = '@type',               default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindText',        { link = '@string',             default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindValue',       { link = '@number',             default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindVariable',    { link = 'Special',             default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpLabelDeprecated', { link = '@lsp.mod.deprecated', default = true })

        -- Documentation window highlights
        vim.api.nvim_set_hl(0, 'BlinkCmpDoc',               { link = 'Normal',           default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpDocBorder',         { link = 'FloatBorder',      default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpDocTitle',          { link = 'Title',            default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpMarkdownCode',       { link = '@text.code',       default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpMarkdownCodeBlock', { link = '@text.code.block',  default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpMarkdownLink',      { link = '@text.uri',        default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpLabel',             { link = '@label',           default = true })
        -- stylua: ignore end
      end)
    end,
  },
}
