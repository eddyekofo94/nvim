local utils_keymaps = require "utils.keymaps"
local map = utils_keymaps.set_keymap
local lmap = utils_keymaps.set_leader_keymap

return { -- LSP Configuration & Plugins
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    -- Automatically install LSPs and related tools to stdpath for Neovim
    { "williamboman/mason.nvim", config = true }, -- NOTE: Must be loaded before dependants
    { "b0o/schemastore.nvim", event = "VeryLazy", ft = { "json" } },
    {
      "folke/lsp-trouble.nvim",
      event = "LspAttach",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      cmd = { "TroubleToggle", "Trouble" },
      config = function()
        require "plugins.lsp.trouble"
      end,
      keys = {
        { "<leader>dD", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "[D]ocument Diagnostics" },
        { "<leader>dW", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "[W]orkspace Diagnostics" },
        { "<leader>dl", "<cmd>TroubleToggle loclist<cr>", desc = "[L]ocation List" },
        { "<leader>dq", "<cmd>TroubleToggle quickfix<cr>", desc = "[Q]uickfix List" },
        {
          "<leader>dt",
          "<cmd>TroubleToggle<cr>",
          desc = "Trouble Toggle",
        },
        {
          "[q",
          function()
            if require("trouble").is_open() then
              require("trouble").previous { skip_groups = true, jump = true }
            else
              local ok, err = pcall(vim.cmd.cprev)
              if not ok then
                vim.notify(err, vim.log.levels.ERROR)
              end
            end
          end,
          desc = "Previous trouble/quickfix item",
        },
        {
          "]q",
          function()
            if require("trouble").is_open() then
              require("trouble").next { skip_groups = true, jump = true }
            else
              local ok, err = pcall(vim.cmd.cnext)
              if not ok then
                ---@diagnostic disable-next-line: param-type-mismatch
                vim.notify(err, vim.log.levels.ERROR)
              end
            end
          end,
          desc = "Next trouble/quickfix item",
        },
      },
    },
    {
      --  INFO: 2023-10-19 - this temporarily disables lsp to save the
      --  CPU usage...
      "hinell/lsp-timeout.nvim",
      enabled = true,
      init = function()
        vim.g.lspTimeoutConfig = {
          stopTimeout = 1000 * 60 * 5, -- ms, timeout before stopping all LSP servers
          startTimeout = 1000 * 10, -- ms, timeout before restart
          silent = false, -- true to suppress notifications
        }
      end,
    },
    {
      "dnlhc/glance.nvim",
      event = "LspAttach",
      config = function()
        require("glance").setup {}
      end,
    },
    {
      "dgagn/diagflow.nvim",
      event = "LspAttach",
      enabled = true,
      config = function()
        require("diagflow").setup {
          toggle_event = { "InsertLeave" },
          enable = function()
            return vim.bo.filetype ~= "lazy"
          end,
          inline_padding_left = 5,
          placement = "top", -- inline
          text_align = "right", -- 'left', 'right'
          show_sign = true, -- set to true if you want to render the diagnostic sign before the diagnostic message
          scope = "cursor", -- 'cursor', 'line' this changes the scope, so instead of showing errors under the cursor, it shows errors on the entire line.
        }
      end,
    },
    {
      "SmiteshP/nvim-navbuddy",
      dependencies = {
        "SmiteshP/nvim-navic",
        "MunifTanjim/nui.nvim",
      },
      keys = {
        {
          "<leader>nn",
          "<cmd>Navbuddy<CR>",
          desc = "Navbuddy open",
        },
      },
      opts = { lsp = { auto_attach = true } },
      config = function()
        require "plugins.lsp.navbuddy"
      end,
    },
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",

    -- Useful status updates for LSP.
    -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
    { "j-hui/fidget.nvim", enabled = false, opts = {} },

    -- `neodev` configures Lua LSP for your Neovim config, runtime and plugins
    -- used for completion, annotations and signatures of Neovim apis
    { "folke/neodev.nvim", opts = {} },
  },
  config = function()
    local lspconfig = require "lspconfig"

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
      callback = function(event)
        local bufnr = event.buf
        local filetype = vim.api.nvim_buf_get_name(bufnr)
        local navic = require "nvim-navic"

        local function opts(desc)
          return { buffer = bufnr, desc = desc }
        end
        -- NOTE: Remember that Lua is a real programming language, and as such it is possible
        -- to define small helper and utility functions so you don't have to repeat yourself.
        --
        -- In this case, we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        -- Jump to the definition of the word under your cursor.
        --  This is where a variable was first declared, or where a function is defined, etc.
        --  To jump back, press <C-t>.
        map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

        -- Find references for the word under your cursor.
        map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

        -- Jump to the implementation of the word under your cursor.
        --  Useful when your language has ways of declaring types without an actual implementation.
        map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

        -- Jump to the type of the word under your cursor.
        --  Useful when you're not sure what type a variable is and you want to see
        --  the definition of its *type*, not where it was *defined*.
        map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

        -- Fuzzy find all the symbols in your current document.
        --  Symbols are things like variables, functions, types, etc.
        map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

        -- Fuzzy find all the symbols in your current workspace.
        --  Similar to document symbols, except searches over your entire project.
        map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

        -- Rename the variable under your cursor.
        --  Most Language Servers support renaming across files, etc.
        map("<leader>lr", vim.lsp.buf.rename, "[Lsp] [r]ename")

        -- Execute a code action, usually your cursor needs to be on top of an error
        -- or a suggestion from your LSP for this to activate.
        map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

        -- Opens a popup that displays documentation about the word under your cursor
        --  See `:help K` for why this keymap.
        map("K", vim.lsp.buf.hover, "Hover Documentation")

        -- WARN: This is not Goto Definition, this is Goto Declaration.
        --  For example, in C this would take you to the header.
        map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

        --  INFO: Glance
        lmap("ld", "<cmd>Glance definitions<cr>", opts "Definitions")
        lmap("lD", "<cmd>Glance type_definitions<cr>", opts "Type definitions")
        lmap("li", "<cmd>Glance implementations<cr>", opts "Implementations")
        lmap("lR", "<cmd>Glance references<cr>", opts "References")

        if filetype == "cpp" then
          vim.api.nvim_buf_set_keymap(0, "n", "<s-f>", "<cmd>ClangdSwitchSourceHeader<CR>", { noremap = true, silent = true })
        end
        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        local client = vim.lsp.get_client_by_id(event.data.client_id)

        if client and client.server_capabilities.documentSymbolProvider then
          navic.attach(client, bufnr)
        end

        if client and client.server_capabilities.documentHighlightProvider then
          local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd("LspDetach", {
            group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = "kickstart-lsp-highlight", buffer = event2.buf }
            end,
          })
        end

        -- The following autocommand is used to enable inlay hints in your
        -- code, if the language server you are using supports them
        --
        -- This may be unwanted, since they displace some of your code
        if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
          map("<leader>th", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
          end, "[T]oggle Inlay [H]ints")
        end
      end,
    })

    local sign = function(opts)
      vim.fn.sign_define(opts.name, {
        texthl = opts.name,
        text = opts.text,
        numhl = "",
      })
    end

    local small_dot = " "

    vim.cmd.highlight "DiagnosticUnderlineError gui=undercurl" -- use undercurl for error, if supported by terminal
    vim.cmd.highlight "DiagnosticUnderlineWarn  gui=undercurl" -- use undercurl for warning, if supported by terminal
    sign { name = "DiagnosticSignError", text = small_dot }
    sign { name = "DiagnosticSignWarn", text = small_dot }
    sign { name = "DiagnosticSignHint", text = small_dot }
    sign { name = "DiagnosticSignInfo", text = small_dot }
    -- LSP servers and clients are able to communicate to each other what features they support.
    --  By default, Neovim doesn't support everything that is in the LSP specification.
    --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
    --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

    -- Enable the following language servers
    --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
    --
    --  Add any additional override configuration in the following tables. Available keys are:
    --  - cmd (table): Override the default command used to start the server
    --  - filetypes (table): Override the default list of associated filetypes for the server
    --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
    --  - settings (table): Override the default settings passed when initializing the server.
    --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
    local servers = {
      clangd = {
        cmd = {
          "clangd",
          "--background-index",
          "--suggest-missing-includes",
          "--all-scopes-completion",
          "--completion-style=detailed",
          "--clang-tidy",
          "--cross-file-rename",
          "--fallback-style=Google",
          "--header-insertion=iwyu",
        },
        -- on_init = custom_init,
        -- on_attach = custom_attach,
        -- capabilities = updated_capabilities,
        init_options = {
          clangdFileStatus = true,
        },
      },
      gopls = {
        -- on_init = on_init,
        capabilities = capabilities,
        cmd = { "gopls" },
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        root_dir = lspconfig.util.root_pattern("go.work", "go.mod", ".git"),
        settings = {
          gopls = {
            completeUnimported = true,
            usePlaceholders = true,
            analyses = {
              unusedparams = true,
            },
          },
        },
        analyses = {
          shadow = true,
          nilness = true,
          unusedparams = true,
          unusedwrite = true,
          useany = true,
        },
        experimentalPostfixCompletions = true,
        gofumpt = true,
        workspace = {
          didChangeWatchedFiles = {
            dynamicRegistration = false,
          },
        },
        setting = {
          gopls = {
            completeUnimported = true,
            usePlaceholders = true,
          },
        },
        usePlaceholders = true,
        hints = {
          assignVariableTypes = true,
          compositeLiteralFields = true,
          compositeLiteralTypes = true,
          constantValues = true,
          functionTypeParameters = true,
          parameterNames = true,
          rangeVariableTypes = true,
        },
        staticcheck = true,
      },
      bashls = {
        -- on_init = custom_init,
        -- on_attach = custom_attach,
        -- capabilities = updated_capabilities,
        filetypes = { "sh", "zsh", "bash", ".zshrc" },
      },
      cmake = {
        init_options = { buildDirectory = "build" },
      },

      pylsp = {
        settings = {
          pylsp = {
            plugins = {
              pycodestyle = {
                ignore = { "W391" },
                maxLineLength = 100,
              },
            },
          },
        },
      },
      yamlls = {
        keyOrdering = false,
        schemaStore = {
          url = "https://www.schemastore.org/api/json/catalog.json",
          enable = true,
        },
      },
      -- rust_analyzer = {},
      -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
      --
      -- Some languages (like typescript) have entire language plugins that can be useful:
      --    https://github.com/pmizio/typescript-tools.nvim
      --
      -- But for many setups, the LSP (`tsserver`) will work just fine
      -- tsserver = {},
      --

      lua_ls = {
        -- cmd = {...},
        -- filetypes = { ...},
        -- capabilities = {},
        settings = {
          Lua = {
            completion = {
              autoRequire = true,
              callSnippet = "Replace",
            },
            format = {
              enable = true,
              defaultConfig = {
                indent_style = "space",
                indent_size = "2",
                max_line_length = "100",
                trailing_table_separator = "smart",
              },
            },
            hint = {
              enable = true,
              arrayIndex = "enable",
              setType = true,
            },
            runtime = {
              -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
              version = "LuaJIT",
            },
            diagnostics = {
              disable = { "missing-fields" },
              globals = { "vim", "use" },
            },
            workspace = {
              -- Make the server aware of Neovim runtime files
              workspace = {
                library = {
                  [vim.fn.expand "$VIMRUNTIME/lua"] = true,
                  [vim.fn.stdpath "data" .. "/lazy/lazy.nvim/lua/lazy"] = true,
                },
                -- library = vim.api.nvim_get_runtime_file("", true),
                maxPreload = 100000,
                preloadFileSize = 10000,
                checkThirdParty = false, -- THIS IS THE IMPORTANT LINE TO ADD
                didChangeWatchedFiles = {
                  dynamicRegistration = false,
                },
              },
            },
            telemetry = {
              enable = false,
            },
          },
          -- Lua = {
          --   completion = {
          --     callSnippet = "Replace",
          --   },
          --   -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
          --   -- diagnostics = { disable = { 'missing-fields' } },
          -- },
        },
      },
    }

    -- Ensure the servers and tools above are installed
    --  To check the current status of installed tools and/or manually install
    --  other tools, you can run
    --    :Mason
    --
    --  You can press `g?` for help in this menu.
    require("mason").setup()

    -- You can add other tools here that you want Mason to install
    -- for you, so that they are available from within Neovim.
    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      "stylua", -- Used to format Lua code
    })
    require("mason-tool-installer").setup { ensure_installed = ensure_installed }

    require("mason-lspconfig").setup {
      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          -- This handles overriding only values explicitly passed
          -- by the server configuration above. Useful when disabling
          -- certain features of an LSP (for example, turning off formatting for tsserver)
          server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
          require("lspconfig")[server_name].setup(server)
        end,
      },
    }
  end,
}
