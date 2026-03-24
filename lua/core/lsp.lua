local lsp = require('utils.lsp')

local M = {}
local attached = {}

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'Setup document highlight on LspAttach.',
  callback = function(args)
    if not require('utils.load').loaded['core.lsp'] then
      return
    end
    local key = args.data.client_id .. ':' .. args.buf
    if attached[key] then
      return
    end
    attached[key] = true
    M.on_attach(
      vim.lsp.get_client_by_id(args.data.client_id),
      args.buf
    )
  end,
})

function M.on_attach(client, buf)
  local group = vim.api.nvim_create_augroup(
    'lsp.document_highlight.' .. buf,
    { clear = true }
  )
  vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
    group = group,
    buffer = buf,
    callback = function()
      local clients = vim.lsp.get_clients({ bufnr = buf })
      for _, c in ipairs(clients) do
        if c:supports_method('textDocument/documentHighlight', buf) then
          vim.lsp.buf.document_highlight()
          return
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = group,
    buffer = buf,
    callback = vim.lsp.buf.clear_references,
  })
  vim.api.nvim_create_autocmd('LspDetach', {
    group = group,
    buffer = buf,
    callback = function(detach_args)
      if detach_args.data.client_id == client.id then
        vim.lsp.buf.clear_references()
        local remaining = vim.lsp.get_clients({ bufnr = buf })
        local has_highlight = vim.iter(remaining):any(function(c)
          return c.id ~= detach_args.data.client_id
            and c:supports_method('textDocument/documentHighlight', buf)
        end)
        if not has_highlight then
          vim.api.nvim_del_augroup_by_id(group)
        end
      end
    end,
  })
end

vim.lsp.config(
  '*',
  vim.tbl_deep_extend('force', lsp.default_config, {
    capabilities = {
      textDocument = {
        sync = {
          changes = false,
        },
      },
    },
  })
)

-- Override to perform additional checks on starting language servers
vim.lsp.start = lsp.start

-- Enable all LSP servers immediately
-- This module is already lazy-loaded on first FileType event (see init.lua),
-- so we can enable servers directly without another deferred autocmd
for _, dir in ipairs(vim.api.nvim__get_runtime({ 'lsp' }, true, {})) do
  for config_file in vim.fs.dir(dir) do
    vim.lsp.enable(vim.fn.fnamemodify(config_file, ':r'))
  end
end

-- Show notification if no references, definition, declaration,
-- implementation or type definition is found
do
  local methods = {
    'textDocument/references',
    'textDocument/definition',
    'textDocument/declaration',
    'textDocument/implementation',
    'textDocument/typeDefinition',
  }

  for _, method in ipairs(methods) do
    local obj_name = method:match('/(%w*)$'):gsub('s$', '')
    local handler = vim.lsp.handlers[method]

    vim.lsp.handlers[method] = function(err, result, ctx, ...)
      if not result or vim.tbl_isempty(result) then
        vim.notify('[LSP] no ' .. obj_name .. ' found')
        return
      end

      -- textDocument/definition can return Location or Location[]
      -- https://microsoft.github.io/language-server-protocol/specifications/specification-current/#textDocument_definition
      if not vim.islist(result) then
        result = { result }
      end

      if #result == 1 then
        vim.lsp.util.show_document(
          result[1],
          vim.lsp.get_client_by_id(ctx.client_id).offset_encoding,
          { focus = true }
        )
        return
      end

      handler(err, result, ctx, ...)
    end
  end
end

-- Configure hovering window style
-- Hijack LSP floating window function to use custom options
do
  local open_floating_preview = vim.lsp.util.open_floating_preview

  ---@param contents table of lines to show in window
  ---@param syntax string of syntax to set for opened buffer
  ---@param opts table with optional fields (additional keys are passed on to |nvim_open_win()|)
  ---@returns bufnr,winnr buffer and window number of the newly created floating preview window
  ---@diagnostic disable-next-line: duplicate-set-field
  function vim.lsp.util.open_floating_preview(contents, syntax, opts)
    return open_floating_preview(
      contents,
      syntax,
      vim.tbl_deep_extend('force', opts, {
        border = 'solid',
        max_width = math.max(80, math.ceil(vim.go.columns * 0.75)),
        max_height = math.max(20, math.ceil(vim.go.lines * 0.4)),
        close_events = {
          'CursorMovedI',
          'CursorMoved',
          'InsertEnter',
          'WinScrolled',
          'WinResized',
          'VimResized',
        },
      })
    )
  end

  -- Use loclist instead of qflist by default when showing document symbols
  local lsp_document_symbol = vim.lsp.buf.document_symbol

  ---@diagnostic disable-next-line: duplicate-set-field
  vim.lsp.buf.document_symbol = function()
    lsp_document_symbol({
      loclist = true,
    })
  end
end

-- Automatically stop LSP servers that no longer attach to any buffers
--
-- Once `LspDetach` is triggered, wait for 60s before checking and
-- stopping servers, in this way the callback will be invoked once
-- every 60 seconds at most and can stop multiple clients at once
-- if possible, which is more efficient than checking and stopping
-- clients on every `LspDetach` events
do
  local lsp_autostop_pending
  local lsp_autostop_timeout_ms = 60000

  vim.api.nvim_create_autocmd('LspDetach', {
    group = vim.api.nvim_create_augroup('lsp.auto_stop', {}),
    desc = 'Automatically stop detached language servers.',
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client then
        vim.notify(
          '[LSP] ' .. client.name .. ' detached',
          vim.log.levels.DEBUG
        )
      end

      if lsp_autostop_pending then
        return
      end
      lsp_autostop_pending = true
      vim.defer_fn(function()
        lsp_autostop_pending = nil
        for _, client in ipairs(vim.lsp.get_clients()) do
          if not next(client.attached_buffers or {}) then
            lsp.soft_stop(client)
          end
        end
      end, lsp_autostop_timeout_ms)
    end,
  })
end

-- Stop LSP servers after inactivity to save RAM
do
  local inactivity_timeout_ms = 120000
  local timers = {}

  local activity_events = {
    'LspAttach',
    'LspStart',
    'BufReadPost',
    'BufWritePost',
    'InsertEnter',
    'TextChangedI',
    'TextChangedP',
  }

  local group =
    vim.api.nvim_create_augroup('lsp.inactivity_timeout', { clear = true })

  vim.api.nvim_create_autocmd('LspStart', {
    group = group,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client then
        vim.notify('[LSP] ' .. client.name .. ' started', vim.log.levels.INFO)
      end
    end,
  })

  vim.api.nvim_create_autocmd(activity_events, {
    group = group,
    callback = function(args)
      local buf = args.buf
      for _, client in ipairs(vim.lsp.get_clients({ buffer = buf })) do
        if timers[client.id] then
          timers[client.id]:close()
        end
        timers[client.id] = vim.defer_fn(function()
          if vim.api.nvim_buf_is_valid(buf) then
            local client = vim.lsp.get_client_by_id(client.id)
            if client and next(client.attached_buffers or {}) then
              vim.notify(
                '[LSP] stopping ' .. client.name .. ' due to inactivity',
                vim.log.levels.DEBUG
              )
              lsp.soft_stop(client)
            end
          end
          timers[client.id] = nil
        end, inactivity_timeout_ms)
      end
    end,
  })

  vim.api.nvim_create_autocmd('LspDetach', {
    group = group,
    callback = function(args)
      local client_id = args.data.client_id
      if timers[client_id] then
        timers[client_id]:close()
        timers[client_id] = nil
      end
    end,
  })
end

-- Keymaps
do
  ---Check if there exists an LS that supports the given method
  ---for the given buffer
  ---@param method string the method to check for
  ---@param bufnr number buffer handler
  local function buf_supports_method(method, bufnr)
    local clients = vim.lsp.get_clients({ bufnr = bufnr })
    for _, client in ipairs(clients) do
      if client:supports_method(method) then
        return true
      end
    end
    return false
  end

  ---Returns a function that takes an LSP action if given method is supported,
  ---else fallback
  ---@param method string lsp method to check
  ---@param action string action callback name
  ---@return fun(fallback: function)
  local function act_if_supports_method(method, action)
    return function(fallback)
      if buf_supports_method(method, 0) then
        vim.lsp.buf[action]()
        return
      end
      fallback()
    end
  end

  local key = require('utils.key')

  -- stylua: ignore start
  key.amend({ 'n', 'x' }, 'gd', act_if_supports_method('textDocument/definition', 'definition'), { desc = 'Go to definition' })
  key.amend({ 'n', 'x' }, 'gD', act_if_supports_method('textDocument/declaration', 'declaration'), { desc = 'Go to declaration' })
  -- stylua: ignore end

  -- stylua: ignore start
  vim.keymap.set({ 'n' }, 'gq;', function() vim.lsp.buf.format() end, { desc = 'Format buffer' })
  vim.keymap.set({ 'i' }, '<M-a>', function() vim.lsp.buf.code_action() end, { desc = 'Show code actions' })
  vim.keymap.set({ 'i' }, '<C-_>', function() vim.lsp.buf.code_action() end, { desc = 'Show code actions' })
  vim.keymap.set({ 'n', 'x' }, 'g/', function() vim.lsp.buf.references() end, { desc = 'Go to references' })
  vim.keymap.set({ 'n', 'x' }, 'g.', function() vim.lsp.buf.implementation() end, { desc = 'Go to implementation' })
  vim.keymap.set({ 'n', 'x' }, 'gb', function() vim.lsp.buf.type_definition() end, { desc = 'Go to type definition' })
  vim.keymap.set({ 'n', 'x' }, '<Leader>r', function() vim.lsp.buf.rename() end, { desc = 'Rename symbol' })
  vim.keymap.set({ 'n', 'x' }, '<Leader>a', function() vim.lsp.buf.code_action() end, { desc = 'Show code actions' })
  vim.keymap.set({ 'n', 'x' }, '<Leader><', function() vim.lsp.buf.incoming_calls() end, { desc = 'Show incoming calls' })
  vim.keymap.set({ 'n', 'x' }, '<Leader>>', function() vim.lsp.buf.outgoing_calls() end, { desc = 'Show outgoing calls' })
  -- vim.keymap.set({ 'n', 'x' }, '<Leader>s', function() vim.lsp.buf.document_symbol() end, { desc = 'Show document symbols' })
  -- stylua: ignore end
end

return M
