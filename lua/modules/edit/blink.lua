return {
  "saghen/blink.cmp",
  enabled = true,
  lazy = false, -- lazy loading handled internally
  -- optional: provides snippets for the snippet source
  dependencies = {
    "niuiic/blink-cmp-rg.nvim",
    "rafamadriz/friendly-snippets",
    "xzbdmw/colorful-menu.nvim",
    dependencies = { "L3MON4D3/LuaSnip", version = "v2.*" },
    {
      "edte/blink-go-import.nvim",
      ft = "go",
      config = function()
        require("blink-go-import").setup()
      end,
    },
  },

  -- use a release tag to download pre-built binaries
  version = "*",
  -- OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
  -- build = 'cargo build --release',
  -- If you use nix, you can build from source using latest nightly rust with:
  -- build = 'nix run .#build-plugin',

  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {},
  config = function()
    require("blink.cmp").setup {
      fuzzy = {
        prebuilt_binaries = {
          download = true,
          -- force_version = "v0.11.0",
        },
      },

      keymap = {
        preset = "super-tab",
        ["<C-e>"] = { "hide" },
        ["<CR>"] = { "select_and_accept", "fallback" },
        ["<C-y>"] = {
          function(cmp)
            cmp.accept { index = 1 }
          end,
        },
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
        ["<Tab>"] = { "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
        ["<C-s>"] = { "show_signature", "hide_signature", "fallback" },
      },

      appearance = {
        highlight_ns = vim.api.nvim_create_namespace "blink_cmp",
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "mono",
        kind_icons = vim.g.kind_icons,
      },

      completion = {
        list = {
          selection = { preselect = false, auto_insert = true },
        },
        accept = { auto_brackets = { enabled = true } },
        menu = {
          min_width = 35,
          border = "single",
          scrolloff = 2,
          scrollbar = true,
          draw = {
            columns = { { "kind_icon" }, { "label", "kind", "source_name", gap = 1 } },
            treesitter = { "lsp" },
            align_to = "none",
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
            },
          },
        },
        documentation = {
          auto_show = true,
          window = {
            border = "single",
            min_width = 35,
            direction_priority = {
              menu_north = { "e", "w" },
              menu_south = { "e", "w" },
            },
          },
        },
        ghost_text = { enabled = false },
      },

      signature = {
        enabled = true,
        window = {
          direction_priority = { "n", "s" },
          border = vim.g.border_style,
        },
      },
      cmdline = {
        keymap = {
          preset = "default",
          ["<C-space>"] = { "show", "hide" },
          ["<C-y>"] = {
            function(cmp)
              cmp.accept { index = 1 }
            end,
          },
          ["<C-e>"] = { "hide", "fallback" },
          ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
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
      },
      sources = {
        default = { "lsp", "snippets", "path", "lazydev", "buffer", "ripgrep", "go_pkgs" },
        min_keyword_length = 0,
        providers = {
          ripgrep = {
            module = "blink-cmp-rg",
            name = "Ripgrep",
            opts = {
              prefix_min_len = 3,
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
                return context.line:sub(1, context.cursor[2]):match "[%w_-]+$" or ""
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
          path = {
            opts = {
              get_cwd = function(_)
                return vim.fn.getcwd()
              end,
            },
          },
        },
      },

      snippets = {
        expand = function(snippet)
          require("luasnip").lsp_expand(snippet)
        end,
        active = function(filter)
          if filter and filter.direction then
            return require("luasnip").jumpable(filter.direction)
          end
          return require("luasnip").in_snippet()
        end,
        jump = function(direction)
          require("luasnip").jump(direction)
        end,
      },

      -- opts_extend = { "sources.default" },
    }
  end,
}
