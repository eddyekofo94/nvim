return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    plugins = { spelling = true },
  },
  config = function()
    require("which-key").setup({ plugins = { presets = { operators = false } } })
    local Util = require("utils")

    local wk = require("which-key")

    local leader_mappings = {
      b = {
        name = "+Buffers",

        b = {
          function()
            require("telescope.builtin").buffers({ sort_lastused = true })
          end,
          "list buffers",
        },
        x = { "<cmd>BufOnly<CR>", "Close all buffers but current" },
      },
      c = {
        name = "+Coding",
        b = { "<cmd>Build<cr>", "Build code" },
        r = { "<cmd>Run<cr>", "Run code" },
        R = { "<cmd>RunAll<cr>", "Build&Run" },
        a = { "<cmd>GoCodeAction<cr>", "Code action" },
        e = { "<cmd>GoIfErr<cr>", "Add if err" },
        h = {
          name = "Helper",
          a = { "<cmd>GoAddTag<cr>", "Add tags to struct" },
          r = { "<cmd>GoRMTag<cr>", "Remove tags to struct" },
          c = { "<cmd>GoCoverage<cr>", "Test coverage" },
          g = { "<cmd>lua require('go.comment').gen()<cr>", "Generate comment" },
          v = { "<cmd>GoVet<cr>", "Go vet" },
          t = { "<cmd>GoModTidy<cr>", "Go mod tidy" },
          i = { "<cmd>GoModInit<cr>", "Go mod init" },
        },
        i = { "<cmd>GoToggleInlay<cr>", "Toggle inlay" },
        j = { "<cmd>'<,'>GoJson2Struct<cr>", "Json to struct" },
        l = { "<cmd>GoLint<cr>", "Run linter" },
        o = { "<cmd>GoPkgOutline<cr>", "Outline" },
        -- r = { "<cmd>GoRun<cr>", "Run" },
        s = { "<cmd>GoFillStruct<cr>", "Autofill struct" },
        t = {
          name = "Tests",
          r = { "<cmd>GoTest<cr>", "Run tests" },
          a = { "<cmd>GoAlt!<cr>", "Open alt file" },
          s = { "<cmd>GoAltS!<cr>", "Open alt file in split" },
          v = { "<cmd>GoAltV!<cr>", "Open alt file in vertical split" },
          u = { "<cmd>GoTestFunc<cr>", "Run test for current func" },
          f = { "<cmd>GoTestFile<cr>", "Run test for current file" },
        },
        x = {
          name = "Code Lens",
          l = { "<cmd>GoCodeLenAct<cr>", "Toggle Lens" },
          a = { "<cmd>GoCodeAction<cr>", "Code Action" },
        },
      },
      d = {
        name = "+diagnostics",
        d = { "<cmd>Telescope diagnostics<cr>", "diagnostics" },
        n = { "<cmd>lua vim.diagnostic.goto_next()<cr>", "diagnostics next" },
        p = { "<cmd>lua vim.diagnostic.goto_prev()<cr>", "diagnostics prev" },
        t = { "<cmd>TroubleToggle<cr>", "trouble" },
      },
      g = {
        name = "+Git",
      },
      l = {
        name = "+lsp",
        a = { "<cmd>lua vim.lsp.buf.code_action()<cr>", "code action" },
        A = { "<cmd>lua vim.lsp.buf.range_code_action()<cr>", "selected action" },
        d = {
          "<cmd>Glance definitions<cr>",
          "definitions",
        },
        D = { "<cmd>Glance type_definitions<cr>", "type definitions" },
        f = { "<cmd>lua vim.lsp.buf.format()<CR>", "format" },
        h = { "<cmd>lua vim.lsp.buf.signature_help()<cr>", "signature help" },
        i = { "<cmd>Glance implementations<cr>", "implementations" },
        I = { "<cmd>LspInfo<cr>", "lsp info" },
        --l = { "<cmd>Lspsaga lsp_finder<cr>", "lsp finder" },
        -- L = { "<cmd>Lspsaga show_line_diagnostics<cr>", "line_diagnostics" },
        p = { "<cmd>lua vim.diagnostic.open_float()<cr>", "preview definition" },
        q = { "<cmd>Telescope quickfix<cr>", "quickfix" },
        r = { "Rename" },
        R = { "<cmd>Glance references<cr>", "References" },
        T = { "<cmd>LspTypeDefinition<cr>", "type definition" }, -- TODO: fix this in the future
        s = { "<cmd>Telescope lsp_document_symbols<cr>", "document symbols" },
        S = { "<cmd>Telescope lsp_workspace_symbols<cr>", "workspace symbols" },
      },
      s = {
        name = "search", -- normally using Telescope
        c = { "<cmd>Telescope current_buffer_fuzzy_find<cr>", "search current buffer" },
        d = { "<cmd>Telescope diagnostics<cr>", "diagnostics" },
        F = { "<cmd>Telescope frecency<cr>", "frecency" },
        n = { "<cmd>NoiceTelescope<cr>", "noice" },
        m = { "<cmd>Telescope marks<cr>", "marks" },
        M = { "<cmd>Telescope man_pages<cr>", "man_pages" },
        p = {
          -- TODO: learn how to create projects
          "<cmd>lua require'telescope'.extensions.project.project{}<cr>",
          "projects",
        },
        -- R = { "<cmd>Telescope oldfiles<cr>", "Recent File" },
        -- s = { Util.telescope("live_grep"), "String" },
        -- S = { "<cmd>Telescope persisted<cr>", "Sessions" },
        T = { "<cmd>TodoTelescope<cr>", "TODO" },
        -- w = { "<cmd>lua require'telescope.builtin'.grep_string()<CR>", "word under cursor" },
        r = { "<cmd>Telescope registers<cr>", "registers" },
        u = { "<cmd>Telescope colorscheme<cr>", "colorschemes" },
        z = { "<cmd>Telescope zoxide list<cr>", "zoxide" },
      },
      S = {
        name = "+Session",
        r = {
          '<cmd>lua require("persistence").load()<cr>',
          "Restore Session",
        },
        l = {
          '<cmd>lua require("persistence").load({ last = true })<cr>',
          "Restore Last Session",
        },
        x = {
          '<cmd>lua require("persistence").stop()<cr>',
          "Don't Save Current Session",
        },
      },
      t = {
        name = "+Terminal",
      },
      -- ["/"] = { "<cmd>CommentToggle<CR>", "comment" },
      -- ["\\"] = { "<cmd>Telescope pickers<cr>", "Searched History" },
      -- [":"] = { "<cmd>Telescope command_history<cr>", "Command History" },
      -- ["="] = { "<C-w>=", "balance windows" },
      ["?"] = { "<cmd>Telescope help_tags<cr>", "find current file" },
      ["~"] = { "<cmd>NvimTreeRefresh<cr>", "refresh tree" },
      h = { ':let @/ = ""<cr>', "Clear Highlight" },
      M = { "<cmd>Mason<cr>", "Mason" },
      N = { "<cmd>Noice<cr>", "Noice" },
      F = { "<cmd>FormatWrite<cr>", "Format & Save File" },
      -- G = { "<cmd>LazyGit<cr>", "Lazygit" },
      -- e = { "Explorer" },
      L = { "<cmd>Lazy<cr>", "Lazy" },
      o = {
        name = "Add line below",
        o = {
          ':<C-u>call append(line("."),   repeat([""], v:count1))<CR>',
          "inset line",
        },
      },
      O = {
        name = "Add line above",
        O = {
          ':<C-u>call append(line(".")-1, repeat([""], v:count1))<CR>',
          "inset line",
        },
      },
      -- p = { "<cmd>Telescope find_files<cr>", "Find File" },
      P = {
        "<cmd>lua require'telescope'.extensions.project.project{}<cr>",
        "Find Project",
      },
      -- r = { "<cmd>Telescope resume<cr>", "Resume search" },
      U = { "<cmd>UndotreeShow<cr>", "Undotree show" },
      -- v = { "<C-W>v", "Split Right" },
      -- Q = { ":cclose<cr>", "close quickfix" },
      W = { "<C-W>q", "Close Window" },
      x = {
        name = "Debugger",
        b = {
          function()
            require("dap").toggle_breakpoint()
          end,
          "Toggle Breakpoint",
        },
        B = {
          function()
            require("dap").clear_breakpoints()
          end,
          "Clear Breakpoints",
        },
        c = {
          function()
            require("dap").continue()
          end,
          "Continue",
        },
        i = {
          function()
            require("dap").step_into()
          end,
          "Step Into",
        },
        -- g = {
        --     function()
        --         require("dap-go").debug_test()
        --         require("dapui").toggle()
        --     end,
        --     "Debug Go Test",
        -- },
        l = {
          function()
            require("dapui").float_element("breakpoints")
          end,
          "List Breakpoints",
        },
        o = {
          function()
            require("dap").step_over()
          end,
          "Step Over",
        },
        q = {
          function()
            require("dap").close()
          end,
          "Close Session",
        },
        Q = {
          function()
            require("dap").terminate()
          end,
          "Terminate",
        },
        r = {
          function()
            require("dap").repl.toggle()
          end,
          "REPL",
        },
        s = {
          function()
            require("dapui").float_element("scopes")
          end,
          "Scopes",
        },
        t = {
          function()
            require("dapui").float_element("stacks")
          end,
          "Threads",
        },
        u = {
          function()
            require("dapui").toggle()
          end,
          "Toggle Debugger UI",
        },
        w = {
          function()
            require("dapui").float_element("watches")
          end,
          "Watches",
        },
        x = {
          function()
            require("dap.ui.widgets").hover()
          end,
          "Inspect",
        },
      },
      z = { "<cmd>ZenMode<cr>", "zen mode" },
    }

    -- local next_movement_mappings = {
    --     ["]"] = { name = "next", c = { "next git hunk" }, d = { "next diagnostic" } },
    -- }
    --
    -- local prev_movement_mappings = {
    --     ["["] = { name = "prev", c = { "prev git hunk" }, d = { "prev diagnostic" } },
    -- }

    -- wk.register(prev_movement_mappings, { prefix = "" })
    -- wk.register(next_movement_mappings, { prefix = "" })

    wk.register(leader_mappings, { prefix = "<leader>" })
  end,
}
