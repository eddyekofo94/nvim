return {
  {
    "nvim-telescope/telescope.nvim",
    event = "VimEnter",
    dependencies = {
      {
        "prochri/telescope-all-recent.nvim",
        enabled = false,
        dependencies = {
          "nvim-telescope/telescope.nvim",
          "kkharji/sqlite.lua",
          -- optional, if using telescope for vim.ui.select
          "stevearc/dressing.nvim",
        },
        config = true,
      },
      "nvim-lua/plenary.nvim",
      { "kyoh86/telescope-windows.nvim" },
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        "nvim-telescope/telescope-fzf-native.nvim",

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = "make",

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable "make" == 1
        end,
      },
      { "nvim-telescope/telescope-frecency.nvim" },
      {
        "ahmedkhalf/project.nvim",
        event = "VeryLazy",
        config = function()
          require("project_nvim").setup {
            scope_chdir = "global",
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
          }
        end,
      },
      {
        "s1n7ax/nvim-window-picker",
        name = "window-picker",
        event = "VeryLazy",
        version = "2.*",
        config = function()
          require("window-picker").setup()
        end,
      },
      { "nvim-telescope/telescope-ui-select.nvim" },
      "jvgrootveld/telescope-zoxide",
      {
        "prochri/telescope-picker-history-action",
        opts = true,
      },
    },
    config = function()
      local actions = require "telescope.actions"
      local Util = require "utils.telescope"
      local themes = require "telescope.themes"

      local utils = require "utils"
      local maps = utils.keymaps:empty_map_table()

      local builtin = require "telescope.builtin"
      local Telescope = require "utils.telescope"
      -- local TelescopePickers = require "utils.telescope_pickers"
      local keymap_utils = require "utils.keymaps"
      local map = keymap_utils.set_keymap

      require("telescope").setup {
        defaults = {
          vimgrep_arguments = {
            "rg",
            "-L",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
            -- "--trim", -- INFO: trim the indentation at the beginning
            "--glob=!.git/",
          },
          prompt_prefix = "   ",
          -- selection_caret = "  ",
          selection_caret = "  ",
          git_worktrees = vim.g.git_worktrees,
          entry_prefix = "  ",
          initial_mode = "insert",
          selection_strategy = "reset",
          sorting_strategy = "ascending",
          layout_strategy = "horizontal",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.55,
              results_width = 0.8,
            },
            vertical = {
              mirror = false,
            },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120,
          },
          pickers = {
            -- frecency = {},
            live_grep = {
              --@usage don't include the filename in the search results
              only_sort_text = true,
            },
            grep_string = {
              only_sort_text = true,
            },
            git_files = {
              mappings = {
                n = {
                  ["<C-H>"] = Util.send_to_harpoon_action,
                },
                i = {
                  ["<C-H>"] = Util.send_to_harpoon_action,
                },
              },
            },
            find_files = {
              find_command = {
                "rg",
                "--hidden",
                "--no-heading",
                "--with-filename",
                "--files",
                "--column",
                "--smart-case",
                "--ignore-file",
                "--iglob",
                "!.git",
              },
              mappings = {
                n = {
                  ["<C-H>"] = Util.send_to_harpoon_action,
                },
                i = {
                  ["<C-H>"] = Util.send_to_harpoon_action,
                },
              },
            },
            buffers = {
              sort_mru = false,
              ignore_current_buffer = true,
              mappings = {
                i = {
                  ["<c-z>"] = actions.delete_buffer, -- this overrides the built in preview scroller
                  ["<c-b>"] = actions.preview_scrolling_down,
                },
                n = {
                  -- BUG: this is still not working
                  ["dd"] = actions.delete_buffer,
                  ["<c-b>"] = actions.preview_scrolling_down,
                },
              },
            },
          },
          file_ignore_patterns = { ".git/.*", "node_modules/.*" },
          file_sorter = require("telescope.sorters").get_fuzzy_file,
          generic_sorter = require("mini.fuzzy").get_telescope_sorter,
          path_display = { "filename_first" },
          dynamic_preview_title = true,
          winblend = 0,
          border = {},
          borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
          color_devicons = true,
          set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
          file_previewer = require("telescope.previewers").vim_buffer_cat.new,
          grep_previewer = require("telescope.previewers").vim_buffer_vimgrep.new,
          qflist_previewer = require("telescope.previewers").vim_buffer_qflist.new,
          -- Developer configurations: Not meant for general override
          buffer_previewer_maker = require("telescope.previewers").buffer_previewer_maker,
          mappings = {
            n = { ["q"] = actions.close },
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
              ["<esc>"] = actions.close,
              ["<C-x>"] = actions.select_horizontal,
              ["<C-v>"] = actions.select_vertical,
              ["<C-Down>"] = actions.cycle_history_next,
              ["<C-Up>"] = actions.cycle_history_prev,
              ["<C-t>"] = actions.select_tab,
              ["<C-f>"] = actions.preview_scrolling_down,
              ["<C-b>"] = actions.preview_scrolling_up,
              ["<C-u>"] = false, --  INFO: 2024-02-19 09:24 AM - Resets prompt
              -- Add up multiple actions
              ["<CR>"] = actions.select_default + actions.center,
              ["<C-,>"] = function()
                require("telescope-picker-history-action").prev_picker()
              end,
              ["<C-.>"] = function()
                require("telescope-picker-history-action").next_picker()
              end,
              ["<C-i>"] = function()
                Util.find("files", { hidden = true, no_ignore = true })()
              end,
              -- ["<C-h>"] = function()
              --   Util.find("files", { hidden = true })()
              -- end,
              ["<C-p>"] = function(prompt_bufnr)
                -- Use nvim-window-picker to choose the window by dynamically attaching a function
                local action_set = require "telescope.actions.set"
                local action_state = require "telescope.actions.state"

                local picker = action_state.get_current_picker(prompt_bufnr)
                picker.get_selection_window = function(picker, entry)
                  local picked_window_id = require("window-picker").pick_window() or vim.api.nvim_get_current_win()
                  -- Unbind after using so next instance of the picker acts normally
                  picker.get_selection_window = nil
                  return picked_window_id
                end

                return action_set.edit(prompt_bufnr, "edit")
              end,
            },
          },
          cache_picker = {
            -- we need to have a picker history we can work with
            num_pickers = 50,
          },
        },

        extensions_list = {
          "zoxide",
          "ui-select",
          "frecency",
          "refactoring",
          "projects",
          "themes",
          "terms",
          "fzf",
          "windows",
        },
        extensions = {
          ["ui-select"] = {
            themes.get_dropdown {},
          },
          frecency = {
            show_scores = true, -- TODO: remove when satisfied
            auto_validate = true,
            hide_current_buffer = true,
            db_safe_mode = false,
            show_unindexed = false,
            ignore_patterns = { "*/tmp/*", "*/undodir/*" },
            workspaces = {
              ["nvim"] = vim.fn.stdpath "config",
              ["dotfiles"] = os.getenv "HOME" .. "/.dotfiles/",
            },
          },
          persisted = {
            theme_conf = { winblend = 10, border = true },
            layout_config = { width = 0.55, height = 0.55 },
            previewer = false,
          },
          -- zoxide = {
          --   themes.get_dropdown {},
          -- },
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      }

      -- Slightly advanced example of overriding default behavior and theme
      map("n", "<leader>/", function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, "[/] Fuzzily search in current buffer")

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      map("n", "<leader>s/", function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = "Live Grep in Open Files",
        }
      end, "[S]earch [/] in Open Files")

      map("n", "<leader>sc", function()
        builtin.commands()
      end, "[S]earch [C]ommands")

      maps.n["<leader><space>"] = { Telescope.find "files", desc = "Find files" }

      maps.n["<leader>p"] = {
        Telescope.find("files", { cwd = "%:p:h" }),
        desc = "Find files current dir",
      }

      maps.n["<leader>sa"] = {
        Telescope.find("files", { follow = true, no_ignore = true, hidden = true }),
        desc = "Find all",
      }

      maps.n["<leader>sP"] = {
        "<cmd> Telescope persisted<CR>",
        desc = "List Sessions",
      }

      maps.n["<leader>ss"] = {
        Telescope.find("live_grep", { cwd = utils.fs:get_root() }),
        desc = "[Root] Live grep",
      }

      maps.n["<leader>s."] = {
        Telescope.find("live_grep", { cwd = "%:p:h" }),
        desc = "[Cur] Live grep",
      }

      maps.n["<leader>sx"] = { Telescope.find "git_status", desc = "Open changed file" }

      maps.n["<leader>bb"] = {
        Telescope.find("buffers", { cwd = false }),
        desc = "[All] List buffers",
      }

      -- maps.n["<leader>s,"] = {
      --   "<cmd>Telescope frecency<cr>",
      --   desc = "[Root] Frecency",
      -- }

      maps.n["<leader>sb"] = {
        Telescope.find "buffers",
        desc = "[Root] List buffers",
      }

      maps.n["<leader>sh"] = { "<cmd> Telescope help_tags<CR>", desc = "tags" }

      maps.n["<leader>sk"] = { Telescope.find "keymaps", desc = "Keymaps" }

      maps.n["<leader>so"] = {
        Telescope.find "oldfiles",
        desc = "Find oldfiles",
      }

      maps.n["<leader>sw"] = {
        function()
          require("telescope").extensions.windows.list()
        end,
        desc = "Find windows",
      }

      maps.n["<leader>sO"] = {
        Telescope.find("oldfiles", { cwd = false }),
        desc = "[Root] Find oldfiles",
      }
      maps.n["<leader>sp"] = { "<cmd> Telescope projects<CR>", desc = "Find projects" }
      maps.n["<leader>sz"] = { "<cmd> Telescope zoxide list<CR>", desc = "Find zoxide" }
      maps.n["<leader>sr"] = { Telescope.find "resume", desc = "resume" }
      maps.n["<leader>st"] = {
        builtin.help_tags,
        desc = "Vim Help Tags",
      }

      -- maps.n["<leader>s/"] = {
      --   Telescope.find "current_buffer_fuzzy_find",
      --   desc = "Find in current buffer",
      -- }
      maps.n["<leader>:"] = {
        Telescope.find "command_history",
        desc = "Old files",
      }

      maps.n["<leader>s*"] = {
        Telescope.find "grep_string",
        desc = "Grep String [Root]",
      }
      maps.n["<leader>*"] = { --  BUG: 2024-04-23 - This seems not to be working.
        Telescope.find("grep_string", { cwd = false }),
        desc = "Grep String",
      }

      maps.x["<leader>s*"] = {
        Telescope.find "grep_string",
        desc = "Grep String [Root]",
      }

      maps.x["<leader>*"] = {
        Telescope.find("grep_string", { cwd = false }),
        desc = "Grep String",
      }

      maps.n["<leader>sd"] = {
        Telescope.find("diagnostics", { bufnr = 0 }),
        desc = "Find diagnostics",
      }

      -- maps.n["<leader>lO"] = {
      --   TelescopePickers.lsp_outgoing_calls(),
      --   desc = "Inc calls",
      -- }

      -- maps.n["<leader>sI"] = {
      --   TelescopePickers.lsp_incoming_calls(),
      --   desc = "Inc calls",
      -- }

      maps.n["<c-]>"] = {
        Telescope.find("lsp_definitions", { jump_type = "vsplit", reuse_win = true }),
        desc = "definition",
      }

      maps.n["<leader>sc"] = {
        Telescope.config_files(),
        desc = "Search Configs",
      }

      maps.n["<leader>sL"] = {
        function()
          require("telescope.builtin").find_files { cwd = require("lazy.core.config").options.root }
        end,
        desc = "[Lazy] Find Plugin File",
      }

      keymap_utils.set_mappings(maps)

      -- setup number and wrap for telescope previewer
      vim.api.nvim_create_autocmd("User", {
        pattern = "TelescopePreviewerLoaded",
        callback = function(args)
          vim.wo.number = true
          vim.wo.wrap = true
        end,
      })
    end,
  },
}
