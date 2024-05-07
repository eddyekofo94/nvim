-- EXAMPLE
local on_init = require('utils.lsp.lspconfig').on_init
local capabilities = require('utils.lsp.lspconfig').capabilities
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local utils_keymaps = require 'utils.keymaps'
local map = utils_keymaps.set_keymap
local lmap = utils_keymaps.set_leader_keymap

local lspconfig = require 'lspconfig'

require('neodev').setup {
  library = { plugins = { 'nvim-dap-ui' }, types = true },
}

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)

    if client.server_capabilities.completionProvider then
      vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
    end
    if client.server_capabilities.definitionProvider then
      vim.bo[bufnr].tagfunc = 'v:lua.vim.lsp.tagfunc'
    end

    local function opts(desc)
      return { buffer = bufnr, desc = desc }
    end

    map('n', 'gD', vim.lsp.buf.declaration, opts 'Lsp Go to declaration')
    map('n', 'K', vim.lsp.buf.hover, opts 'Lsp hover information')
    --  INFO: 2024-04-11 15:55 PM - Using Glance
    -- map("n", "gd", vim.lsp.buf.definition, opts "Lsp Go to definition")
    -- map("n", "gi", vim.lsp.buf.implementation, opts "Lsp Go to implementation")
    map('n', '<leader>lh', vim.lsp.buf.signature_help, opts 'Lsp Show signature help')
    map('n', '<leader>la', vim.lsp.buf.add_workspace_folder, opts 'Lsp Add workspace folder')
    map('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts 'Lsp Remove workspace folder')

    map('n', '<leader>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts 'Lsp List workspace folders')

    -- map("n", "<leader>D", vim.lsp.buf.type_definition, opts "Lsp Go to type definition")

    map({ 'n', 'x' }, '<leader>lr', function()
      return vim.lsp.buf.rename
    end, opts 'Lsp Renamer')

    map({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts 'Lsp Code action')
    map('n', 'gr', vim.lsp.buf.references, opts 'Lsp Show references')

    --  INFO: Glance
    lmap('ld', '<cmd>Glance definitions<cr>', opts 'Definitions')
    lmap('lD', '<cmd>Glance type_definitions<cr>', opts 'Type definitions')
    lmap('li', '<cmd>Glance implementations<cr>', opts 'Implementations')
    lmap('lR', '<cmd>Glance references<cr>', opts 'References')

    -- setup signature popup
    -- if conf.signature and client.server_capabilities.signatureHelpProvider then
    --   require("nvchad.lsp.signature").setup(client, bufnr)
    -- end

    ----Inlay hints
    --  BUG: 2024-04-11 16:06 PM - Not working
    if vim.fn.has 'nvim-0.10' == 1 then
      vim.g.inlay_hints_visible = false

      local function toggle_inlay_hints()
        if vim.g.inlay_hints_visible then
          vim.g.inlay_hints_visible = false
          vim.lsp.inlay_hint.enable(bufnr, false)
        else
          if client.server_capabilities.inlayHintProvider then
            vim.g.inlay_hints_visible = true
            vim.lsp.inlay_hint.enable(bufnr, true)
          else
            print 'no inlay hints available'
          end
        end
      end

      map('n', '<leader>lk', toggle_inlay_hints, 'vim.lsp.inlay_hint')
    end
  end,
})

local sign = function(opts)
  vim.fn.sign_define(opts.name, {
    texthl = opts.name,
    text = opts.text,
    numhl = '',
  })
end

local small_dot = ' '

vim.cmd.highlight 'DiagnosticUnderlineError gui=undercurl' -- use undercurl for error, if supported by terminal
vim.cmd.highlight 'DiagnosticUnderlineWarn  gui=undercurl' -- use undercurl for warning, if supported by terminal
sign { name = 'DiagnosticSignError', text = small_dot }
sign { name = 'DiagnosticSignWarn', text = small_dot }
sign { name = 'DiagnosticSignHint', text = small_dot }
sign { name = 'DiagnosticSignInfo', text = small_dot }

vim.diagnostic.config {
  underline = true,
  -- Hide/Show virtual text
  virtual_text = {
    prefix = ' ',
    severity_limit = 'Warning',
    spacing = 4,
  },
  signs = true,
  update_in_insert = true,
  float = {
    border = 'rounded',
    -- source = "always",
    header = '',
    prefix = '',
    focusable = false,
  },
}

lspconfig.vimls.setup {
  on_init = on_init,
  capabilities = capabilities,
}

lspconfig.lua_ls.setup {
  on_init = on_init,
  capabilities = capabilities,
  settings = {
    Lua = {
      completion = {
        autoRequire = true,
        callSnippet = 'Replace',
      },
      format = {
        enable = true,
        defaultConfig = {
          indent_style = 'space',
          indent_size = '2',
          max_line_length = '100',
          trailing_table_separator = 'smart',
        },
      },
      hint = {
        enable = true,
        arrayIndex = 'enable',
        setType = true,
      },
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
      },
      diagnostics = {
        disable = { 'missing-fields' },
        globals = { 'vim', 'use' },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        workspace = {
          library = {
            [vim.fn.expand '$VIMRUNTIME/lua'] = true,
            [vim.fn.expand '$VIMRUNTIME/lua/vim/lsp'] = true,
            [vim.fn.stdpath 'data' .. '/lazy/ui/nvchad_types'] = true,
            [vim.fn.stdpath 'data' .. '/lazy/lazy.nvim/lua/lazy'] = true,
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
  },
}

lspconfig.gopls.setup {
  on_init = on_init,
  capabilities = capabilities,
  cmd = { 'gopls' },
  filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
  root_dir = lspconfig.util.root_pattern('go.work', 'go.mod', '.git'),
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
}

lspconfig.pylsp.setup {
  on_init = on_init,
  capabilities = capabilities,
  settings = {
    pylsp = {
      plugins = {
        pycodestyle = {
          ignore = { 'W391' },
          maxLineLength = 100,
        },
      },
    },
  },
}

lspconfig.yamlls.setup {
  on_init = on_init,
  keyOrdering = false,
  schemaStore = {
    url = 'https://www.schemastore.org/api/json/catalog.json',
    enable = true,
  },
  capabilities = capabilities,
}

lspconfig.clangd.setup {
  on_init = on_init,
  cmd = {
    'clangd',
    '--background-index',
    '--suggest-missing-includes',
    '--all-scopes-completion',
    '--completion-style=detailed',
    '--clang-tidy',
    '--cross-file-rename',
    '--fallback-style=Google',
    '--header-insertion=iwyu',
  },
  capabilities = capabilities,
  init_options = {
    clangdFileStatus = true,
  },
}

lspconfig.jsonls.setup {
  on_init = on_init,
  capabilities = capabilities,
  settings = {
    json = {
      schemas = require('schemastore').json.schemas(),
      validate = { enable = true },
    },
  },
  setup = {
    commands = {
      Format = {
        function()
          vim.lsp.buf.range_formatting({}, { 0, 0 }, { vim.fn.line '$', 0 })
        end,
      },
    },
  },
}

lspconfig.bashls.setup {
  on_init = on_init,
  capabilities = capabilities,
  filetypes = { 'sh', 'bash' },
}
