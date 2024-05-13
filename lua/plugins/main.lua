return {
  { import = "plugins.configs.mini" },
  { import = "plugins.code" },
  -- LSP
  {
    "ibhagwan/fzf-lua",
    cmd = {
      "FzfLua",
      "F",
      "Ls",
      "Args",
      "Tabs",
      "Tags",
      "Files",
      "Marks",
      "Jumps",
      "Autocmd",
      "Buffers",
      "Changes",
      "Display",
      "Oldfiles",
      "Registers",
      "Highlight",
    },
    keys = {
      "<Leader>.",
      "<Leader>,",
      -- '<Leader>/',
      "<Leader>?",
      '<Leader>"',
      -- '<Leader>o',
      "<Leader>'",
      -- '<Leader>-',
      -- '<Leader>=',
      "<Leader>R",
      "<Leader>F",
      "<Leader>f",
      "<Leader>ff",
      { "<Leader>*", mode = { "n", "x" } },
      { "<Leader>#", mode = { "n", "x" } },
    },
    event = "LspAttach",
    build = "fzf --version",
    init = vim.schedule_wrap(function()
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        local fzf_ui = require "fzf-lua.providers.ui_select"
        -- Register fzf as custom `vim.ui.select()` function if not yet
        -- registered
        if not fzf_ui.is_registered() then
          local _ui_select = fzf_ui.ui_select
          ---Overriding fzf-lua's default `ui_select()` function to use a
          ---custom prompt
          ---@diagnostic disable-next-line: duplicate-set-field
          fzf_ui.ui_select = function(items, opts, on_choice)
            -- Hack: use nbsp after ':' here because currently fzf-lua does
            -- not allow custom prompt and force substitute pattern ':%s?$'
            -- in `opts.prompt` to '> ' as the fzf prompt. We WANT the column
            -- in the prompt, so use nbsp to avoid this substitution.
            -- Also, don't use `opts.prompt:gsub(':?%s*$', ':\xc2\xa0')` here
            -- because it does a non-greedy match and will not substitute
            -- ':' at the end of the prompt, e.g. if `opts.prompt` is
            -- 'foobar: ' then result will be 'foobar: : ', interestingly
            -- this behavior changes in Lua 5.4, where the match becomes
            -- greedy, i.e. given the same string and substitution above the
            -- result becomes 'foobar> ' as expected.
            opts.prompt = opts.prompt and vim.fn.substitute(opts.prompt, ":\\?\\s*$", ":\xc2\xa0", "")
            _ui_select(items, opts, on_choice)
          end

          -- Use the register function provided by fzf-lua. We are using this
          -- wrapper instead of directly replacing `vim.ui.selct()` with fzf
          -- select function because in this way we can pass a callback to this
          -- `register()` function to generate fzf opts in different contexts,
          -- see https://github.com/ibhagwan/fzf-lua/issues/755
          -- Here we use the callback to achieve adaptive height depending on
          -- the number of items, with a max height of 10, the `split` option
          -- is basically the same as that used in fzf config file:
          -- lua/configs/fzf-lua.lua
          fzf_ui.register(function(_, items)
            return {
              winopts = {
                split = string.format(
                  [[
                    let tabpage_win_list = nvim_tabpage_list_wins(0) |
                    \ call v:lua.require'utils.win'.saveheights(tabpage_win_list) |
                    \ call v:lua.require'utils.win'.saveviews(tabpage_win_list) |
                    \ unlet tabpage_win_list |
                    \ let g:_fzf_vim_lines = &lines |
                    \ let g:_fzf_leave_win = win_getid(winnr()) |
                    \ let g:_fzf_splitkeep = &splitkeep | let &splitkeep = "topline" |
                    \ let g:_fzf_cmdheight = &cmdheight | let &cmdheight = 0 |
                    \ let g:_fzf_laststatus = &laststatus | let &laststatus = 0 |
                    \ botright %dnew |
                    \ let w:winbar_no_attach = v:true |
                    \ setlocal bt=nofile bh=wipe nobl noswf wfh
                  ]],
                  math.min(10 + vim.go.ch + (vim.go.ls == 0 and 0 or 1), #items + 1)
                ),
              },
            }
          end)
        end
        vim.ui.select(...)
      end
      vim.api.nvim_create_autocmd("CmdlineEnter", {
        group = vim.api.nvim_create_augroup("FzfLuaCreateCmdAbbr", {}),
        once = true,
        callback = function(info)
          local keymap = require "utils.keymaps"
          keymap.command_abbrev("ls", "Ls")
          keymap.command_abbrev("tabs", "Tabs")
          keymap.command_abbrev("tags", "Tags")
          keymap.command_abbrev("files", "Files")
          keymap.command_abbrev("marks", "Marks")
          keymap.command_abbrev("buffers", "Buffers")
          keymap.command_abbrev("changes", "Changes")
          keymap.command_abbrev({ "ar", "args" }, "Args")
          keymap.command_abbrev({ "ju", "jumps" }, "Jumps")
          keymap.command_abbrev({ "au", "autocmd" }, "Autocmd")
          keymap.command_abbrev({ "di", "display" }, "Display")
          keymap.command_abbrev({ "o", "oldfiles" }, "Oldfiles")
          keymap.command_abbrev({ "hi", "highlight" }, "Highlight")
          keymap.command_abbrev({ "reg", "registers" }, "Registers")
          vim.api.nvim_del_augroup_by_id(info.group)
          return true
        end,
      })
    end),
    config = function()
      require "plugins.configs.fzf-lua"
    end,
  },
  -- Better notifications and messagess
  {
    "folke/noice.nvim",
    enabled = true,
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require "plugins.configs.noice"
    end,
  },
  {
    "ariel-frischer/bmessages.nvim",
    event = "CmdlineEnter",
    opts = {},
  },
  {
    "rcarriga/nvim-notify",
    event = "BufEnter",
    init = function()
      vim.notify = require "notify"
    end,
  },
  {
    "samjwill/nvim-unception",
    enabled = false,
    init = function()
      vim.g.unception_delete_replaced_buffer = true
      vim.api.nvim_create_autocmd("User", {
        pattern = "UnceptionEditRequestReceived",
        callback = function()
          require("nvterm.terminal").hide "horizontal"
        end,
      })
    end,
  },
  -- Global search and replace within cwd
  {
    "nvim-pack/nvim-spectre",
    enabled = true,
    event = "VeryLazy",
    config = function()
      local spectre = require "spectre"
      vim.keymap.set(
        "n",
        "<leader>S",
        -- spectre.toggle,
        '<cmd>lua require("spectre").toggle()<CR>',
        {
          desc = "Toggle Spectre",
        }
      )
      vim.keymap.set(
        "n",
        "<leader>sW",
        -- spectre.open_visual { select_word = true },
        '<cmd>lua require("spectre").open_visual({select_word=true})<CR>',
        {
          desc = "Search current word",
        }
      )
      vim.keymap.set("v", "<leader>sW", '<esc><cmd>lua require("spectre").open_visual()<CR>', {
        desc = "Search current word",
      })
      vim.keymap.set(
        "n",
        "<leader>sM",
        -- spectre.open_file_search { select_word = true },
        '<cmd>lua require("spectre").open_file_search({select_word=true})<CR>',
        {
          desc = "Search on current file",
        }
      )
      -- vim.keymap.set("n", "<D-S-r>", spectre.toggle, {
      --   desc = "Toggle Spectre",
      -- })
      -- vim.keymap.set("v", "<D-S-r>", spectre.open_visual, {
      --   desc = "Toggle Spectre",
      -- })
    end,
  },
  {
    "notjedi/nvim-rooter.lua",
    lazy = false,
    enabled = false,
    config = function()
      require("nvim-rooter").setup {
        fallback_to_parent = true,
        exclude_filetypes = { "oil" },
      }
    end,
  },

  {
    "williamboman/mason.nvim",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require "plugins.lsp.mason"
    end,
    opts = {
      ensure_installed = {
        "lua-language-server",
        "shellcheck",
        "shfmt",
        "flake8",
        "prettier",
        "vim-language-server",
        "stylua",
        "json-lsp",
        "marksman",
        "yamlls",
        "pylsp",
        "bashls",
        "sqlls",
        "dockerls",
        "glint",
        "gopls",
        "clangd",
      },
    },
  },
  {
    "stevearc/resession.nvim",
    -- enabled = vim.g.resession_enabled == true,
    enabled = false,
    lazy = true,
    event = "VimEnter",
    config = true,
    opts = {
      buf_filter = function(bufnr)
        return require("utils.buffer").is_restorable(bufnr)
      end,
      tab_buf_filter = function(tabpage, bufnr)
        return vim.tbl_contains(vim.t[tabpage].bufs, bufnr)
      end,
      -- extensions = { astronvim = {} },
    },
  },
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      { "<leader>T", "<cmd>TodoQuickFix<cr>", desc = "Search TODO" },
      {
        "]t",
        "<cmd>lua require('todo-comments').jump_next()<cr>",
        { desc = "Next todo comment" },
      },
      {
        "[t",
        "<cmd>lua require('todo-comments').jump_prev()<cr>",
        { desc = "Previous todo comment" },
      },
    },
    opts = require "plugins.configs.todo-comments",
  },
  {
    "stevearc/conform.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.formatexpr = "v:lua.require('conform').formatexpr()"
    end,
    opts = require "plugins.configs.conform",
    keys = {
      {
        "<leader>cf",
        '<cmd>lua require("conform").format()<cr>',
        desc = "Format current file",
      },
    },
  },
  {
    "ThePrimeagen/harpoon",
    event = "VeryLazy",
    config = function()
      require "plugins.configs.harpoon"
    end,
  },
  {
    "smjonas/live-command.nvim",
    event = "CmdlineEnter",
    config = function()
      require("live-command").setup {
        commands = {
          Norm = { cmd = "norm" },
        },
      }
    end,
  },

  {
    "lcheylus/overlength.nvim",
    event = "BufReadPre",
    config = function()
      require("overlength").setup {
        bg = "#840000",
        default_overlength = 80, -- INFO: seems to not work
        disable_ft = { "help", "dashboard", "which-key", "lazygit", "term" },
      }
      require("overlength").set_overlength({ "go", "lua", "vim" }, 120)
      require("overlength").set_overlength({ "cpp", "bash" }, 80)
      require("overlength").set_overlength({ "rust", "python" }, 100)
    end,
  },
  {
    "folke/which-key.nvim",
    enabled = true,
    event = "VeryLazy",
    opts = {
      disable = { filetypes = { "TelescopePrompt" } },
    },
    config = require "plugins.configs.which-key",
  },
  {
    "ahmedkhalf/project.nvim",
    -- can't use 'opts' because module has non standard name 'project_nvim'
    config = function()
      require("project_nvim").setup {
        scope_chdir = "global",
        patterns = {
          ".git",
          "package.json",
          "go.mod",
          "Makefile",
          "pom.xml",
          "requirements.yml",
          "pyrightconfig.json",
          "pyproject.toml",
        },
        detection_methods = { "lsp", "pattern" },
      }
    end,
  },
  {
    "folke/flash.nvim",
    -- event = "VeryLazy",
    lazy = false,
    enabled = true,
    -- @type Flash.Config
    opts = {
      search = {
        multi_window = true,
      },
    },
    -- config = function()
    --   require "configs.flash"
    -- end,
    keys = require "plugins.configs.flash",
  },
  {
    "RRethy/vim-illuminate",
    -- INFO: disabled for now
    enabled = false,
    event = "BufWinEnter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    config = require "plugins.configs.illuminate",
  },
  {
    "utilyre/sentiment.nvim",
    version = "*",
    enabled = true,
    event = "VeryLazy", -- keep for lazy loading
    opts = {
      -- config
    },
    init = function()
      -- `matchparen.vim` needs to be disabled manually in case of lazy loading
      vim.g.loaded_matchparen = 1
    end,
  },
  {
    "andymass/vim-matchup",
    enabled = false,
    event = "VeryLazy",
    init = function()
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
    end,
  },
  {
    "smoka7/multicursors.nvim",
    event = "VeryLazy",
    dependencies = {
      "smoka7/hydra.nvim",
    },
    opts = {},
    cmd = {
      "MCstart",
      "MCvisual",
      "MCclear",
      "MCpattern",
      "MCvisualPattern",
      "MCunderCursor",
    },
    keys = {
      {
        mode = { "v", "n" },
        "<Leader>mc",
        "<cmd>MCstart<cr>",
        desc = "Create a selection for selected text or word under the cursor",
      },
    },
  },
  {
    "nacro90/numb.nvim",
    event = "VeryLazy",
    opts = {
      show_numbers = true,
      show_cursorline = true,
      number_only = false,
      centered_peeking = true,
    },
  },
  {
    "folke/zen-mode.nvim",
    event = "VeryLazy",
    dependencies = {
      {
        "folke/twilight.nvim",
        config = function()
          require("twilight").setup {
            context = -1,
            treesitter = true,
          }
        end,
      },
    },
    config = require "plugins.configs.zen",
  },

  {
    "NMAC427/guess-indent.nvim",
    event = "VeryLazy",
    config = function(_, opts)
      require("guess-indent").setup(opts)
      vim.cmd.lua {
        args = { "require('guess-indent').set_from_buffer('auto_cmd')" },
        mods = { silent = true },
      }
    end,
  },

  {
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    -- event = "VeryLazy",
    lazy = false,
    opts = require("plugins.configs.ufo").opts,
    init = require("plugins.configs.ufo").init(),
    config = function(opts)
      require("plugins.configs.ufo").config(opts)
    end,
  },
  {
    "NvChad/nvim-colorizer.lua",
    event = "BufWinEnter",
    config = function(_, opts)
      require("colorizer").setup(opts)

      -- execute colorizer as soon as possible
      vim.defer_fn(function()
        require("colorizer").attach_to_buffer(0)
      end, 0)
    end,
    opts = {
      user_default_options = {
        names = false,
        rgb_fn = true,
        hsl_fn = true,
        mode = "virtualtext",
      },
    },
  },
  {
    "arsham/indent-tools.nvim",
    event = "VeryLazy",
    dependencies = {
      "arsham/arshlib.nvim",
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = true,
    -- keys = { "]i", "[i", { "v", "ii" }, { "o", "ii" } },
    -- or to provide configuration
    -- config = { normal = {..}, textobj = {..}},
  },
  {
    -- INFO: does this work?
    "ironhouzi/starlite-nvim",
    event = "WinEnter",
    config = function()
      local map = vim.keymap.set
      local default_options = { silent = true }
      map("n", "*", ":lua require'starlite'.star()<cr>", default_options)
      map("n", "g*", ":lua require'starlite'.g_star()<cr>", default_options)
      map("n", "#", ":lua require'starlite'.hash()<cr>", default_options)
      map("n", "g#", ":lua require'starlite'.g_hash()<cr>", default_options)
    end,
  },
  {
    "chrisgrieser/nvim-spider",
    opts = {
      skipInsignificantPunctuation = true,
    },
    event = "VeryLazy",
    keys = { "w", "e", "b", "ge" },
    config = function()
      require "plugins.configs.spider"
    end,
  },
  {
    "ashfinal/qfview.nvim",
    event = "UIEnter",
    opts = {},
  },
  {
    "gabrielpoca/replacer.nvim",
    event = "VeryLazy",
    opts = { rename_files = true },
    keys = {
      {
        "<leader>qf",
        function()
          require("replacer").run()
        end,
        desc = "run replacer.nvim",
      },
      {
        "<leader>qs",
        function()
          require("replacer").save()
        end,
        desc = "save replacer.nvim",
      },
    },
  },
  {
    "ten3roberts/qf.nvim",
    enabled = false,
    config = function()
      require("qf").setup {}
    end,
  },
  {
    -- INFO: jj == esc
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
      require("better_escape").setup()
    end,
  },
  {
    "nvim-zh/colorful-winsep.nvim",
    enabled = true,
    branch = "main", -- change to alpha if satisfied with its updates
    event = { "WinNew" },
    opts = require "plugins.configs.winsep",
    config = true,
  },
  {
    "chrisgrieser/nvim-early-retirement",
    event = "VeryLazy",
    config = true,
    opts = require "plugins.configs.early-retirement",
  },
  {
    "beauwilliams/focus.nvim",
    enabled = true,
    event = "VimEnter",
    cmd = {
      "FocusAutoresize",
    },
    config = function()
      require "plugins.configs.focus"
    end,
  },

  {
    "simonmclean/triptych.nvim",
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "nvim-tree/nvim-web-devicons", -- optional
    },
    keys = {
      { "<leader>-", "<cmd>Triptych<CR>", desc = "File explorere [Triptych]" },
    },
    config = function()
      require "plugins.configs.triptych"
    end,
  },
  {
    "kylechui/nvim-surround",
    event = "VeryLazy",
    keys = {
      { "s", mode = { "n", "x", "o" } },
      { "S", mode = "x" },
    },
    config = function()
      require "plugins.configs.nvim-surround"
    end,
  },
  -- {
  --   "williamboman/mason.nvim",
  --   opts = {
  --     ensure_installed = {
  --       "gopls",
  --     },
  --   },
  -- },
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      {
        "dreamsofcode-io/nvim-dap-go",
        ft = "go",
        dependencies = "mfussenegger/nvim-dap",
        config = function(_, opts)
          require("dap-go").setup(opts)
        end,
      },
    },
  },
  {
    "olexsmir/gopher.nvim",
    ft = "go",
    config = function(_, opts)
      require("gopher").setup(opts)
    end,
    build = function()
      vim.cmd [[silent! GoInstallDeps]]
    end,
  },
}
