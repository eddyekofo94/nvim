---@type pack.spec
return {
  src = 'https://github.com/stevearc/oil.nvim',
  data = {
    deps = {
      {
        src = 'https://github.com/kyazdani42/nvim-web-devicons',
        data = { optional = true },
      },
      {
        -- Ensure that img-clip is loaded before oil to prevent its `vim.paste`
        -- handler from overriding oil's
        src = 'https://github.com/HakonHarnes/img-clip.nvim',
        data = { optional = true },
      },
    },
    cmds = 'Oil',
    keys = {
      mode = { 'n', 'x' },
      lhs = '-',
      opts = { desc = "Edit current file's directory" },
    },
    ---Load oil on startup only when editing a directory
    init = function(spec, path)
      vim.g.loaded_fzf_file_explorer = 0
      vim.g.loaded_netrw = 0
      vim.g.loaded_netrwPlugin = 0
      vim.api.nvim_create_autocmd('BufEnter', {
        nested = true,
        -- Use `vim.schedule()` here to wait session to be loaded and
        -- buffer attributes, e.g. buffer name, to be updated before
        -- checking if the buffer is a directory buffer
        callback = vim.schedule_wrap(function(args)
          local buf = args.buf

          if
            not vim.api.nvim_buf_is_valid(buf)
            or vim.fn.bufwinid(buf) == -1
            or vim.bo[buf].bt ~= ''
          then
            return
          end

          local bufname = vim.api.nvim_buf_get_name(buf)
          if bufname == '' then
            return
          end

          -- Only load oil.nvim if the buffer is a non-existing file
          -- (e.g. scp:// or oil:// paths) or is an existing directory
          local stat = vim.uv.fs_stat(bufname)
          if stat and stat.type ~= 'directory' then
            return
          end

          require('utils.pack').load(spec, path)
          return true
        end),
      })
    end,
    preload = function()
      local to_lpeg = vim.glob.to_lpeg

      ---HACK: override `vim.glob.to_lpeg()` to avoid 'invalid glob' error, see
      ---https://github.com/stevearc/oil.nvim/issues/672
      ---@param pattern string
      ---@return vim.lpeg.Pattern|string
      ---@diagnostic disable-next-line: duplicate-set-field
      function vim.glob.to_lpeg(pattern)
        local ok, lpeg_pattern = pcall(to_lpeg, pattern)
        if not ok then
          return pattern
        end
        return lpeg_pattern
      end
    end,
    postload = function()
      local oil = require('oil')
      local oil_config = require('oil.config')
      local oil_view = require('oil.view')
      local icons = require('utils.static').icons
      local icon_file = vim.trim(icons.File)
      local icon_dir = vim.trim(icons.Folder)

      ---Change window-local directory to `dir`
      ---@param dir string
      ---@return nil
      local function lcd(dir)
        local ok = pcall(vim.cmd.lcd, {
          dir,
          mods = {
            silent = true,
            emsg_silent = true,
          },
        })
        if not ok then
          vim.notify('[oil.nvim] failed to cd to ' .. dir, vim.log.levels.WARN)
        end
      end

      local permission_hlgroups = setmetatable({
        ['-'] = 'OilPermissionNone',
        ['r'] = 'OilPermissionRead',
        ['w'] = 'OilPermissionWrite',
        ['x'] = 'OilPermissionExecute',
        ['s'] = 'OilPermissionSetuid',
      }, {
        __index = function()
          return 'OilDir'
        end,
      })

      local type_hlgroups = setmetatable({
        ['-'] = 'OilTypeFile',
        ['d'] = 'OilTypeDir',
        ['p'] = 'OilTypeFifo',
        ['l'] = 'OilTypeLink',
        ['s'] = 'OilTypeSocket',
      }, {
        __index = function()
          return 'OilTypeFile'
        end,
      })

      oil.setup({
        columns = {
          {
            'type',
            icons = {
              directory = 'd',
              fifo = 'p',
              file = '-',
              link = 'l',
              socket = 's',
            },
            highlight = function(type_str)
              return type_hlgroups[type_str]
            end,
          },
          {
            'permissions',
            highlight = function(permission_str)
              local hls = {}
              for i = 1, #permission_str do
                local char = permission_str:sub(i, i)
                table.insert(hls, { permission_hlgroups[char], i - 1, i })
              end
              return hls
            end,
          },
          { 'size', highlight = 'Number' },
          { 'mtime', highlight = 'String' },
          {
            'icon',
            default_file = icon_file,
            directory = icon_dir,
            add_padding = false,
          },
        },
        buf_options = {
          textwidth = 0,
          buflisted = false,
          bufhidden = 'hide',
        },
        win_options = {
          spell = false,
          number = false,
          relativenumber = false,
          signcolumn = 'no',
          foldcolumn = '0',
          colorcolumn = '',
          winbar = '',
        },
        watch_for_changes = false,
        delete_to_trash = true,
        skip_confirm_for_simple_edits = true,
        prompt_save_on_select_new_entry = true,
        use_default_keymaps = false,
        view_options = {
          show_hidden = true,
          is_always_hidden = function(name)
            return name == '..'
          end,
        },
        keymaps = {
          ['g?'] = 'actions.show_help',
          ['K'] = preview_mapping,
          ['<C-k>'] = preview_mapping,
          ['<C-P>'] = preview_mapping,
          ['<LocalLeader>0'] = {
            function()
              local utils = require('utils')
              local current_dir = require('oil').get_current_dir()
              local root = utils.fs.cwd_dir(current_dir) or vim.fn.getcwd()
              require('oil').open(root)
            end,
            mode = 'n',
            nowait = true,
            desc = 'Oil: Open Project Root',
          },
          ['-'] = 'actions.parent',
          ['<C-->'] = 'actions.parent',
          ['<C-h>'] = 'actions.parent',
          ['<C-l>'] = 'actions.select',
          ['q'] = 'actions.close',
          ['='] = 'actions.select',
          ['+'] = 'actions.select',
          ['<CR>'] = 'actions.select',
          ['<C-.>'] = 'actions.toggle_hidden',
          ['gh'] = 'actions.toggle_hidden',
          -- Conflict with `gs...` keymaps defined in
          -- `lua/pack/specs/opt/nvim-treesitter-textobjects.lua`
          -- and `lua/pack/specs/opt/treesj.lua`, use `nowait` to avoid lagging
          -- due to conflict
          ['gs'] = { 'actions.change_sort', mode = 'n', nowait = true },
          ['gx'] = 'actions.open_external',
          ['<LocalLeader>y'] = 'actions.copy_to_system_clipboard',
          ['<LocalLeader>p'] = 'actions.paste_from_system_clipboard',
          -- Drag and drop
          -- Source: https://github.com/ndavd/dotfiles/blob/7af6efa64007c9e28ca5461c101034c2d5d53000/.config/nvim/lua/plugins/oil.lua#L15
          ['<LocalLeader>d'] = {
            mode = { 'x', 'n' },
            buffer = true,
            desc = 'Drag and drop entry under the cursor',
            callback = function()
              local lnum_cur = vim.fn.line('.')
              local lnum_other = vim.fn.line('v')
              local entries = {}
              for lnum = math.min(lnum_cur, lnum_other), math.max(lnum_cur, lnum_other) do
                table.insert(entries, oil.get_entry_on_line(0, lnum))
              end
              local dir = oil.get_current_dir()
              if vim.tbl_isempty(entries) or not dir then
                return
              end
              if vim.fn.executable('dragon-drop') == 0 then
                vim.notify(
                  '[oil.nvim] `dragon-drop` is not executable',
                  vim.log.levels.WARN
                )
                return
              end
              vim.system({
                'dragon-drop',
                unpack(vim
                  .iter(entries)
                  :map(function(entry)
                    return vim.fs.joinpath(dir, entry.name)
                  end)
                  :totable()),
              })
            end,
          },
          ['go'] = {
            mode = 'n',
            buffer = true,
            desc = 'Choose an external program to open the entry under the cursor',
            callback = function()
              local entry = oil.get_cursor_entry()
              local dir = oil.get_current_dir()
              if not entry or not dir then
                return
              end
              local entry_path = vim.fs.joinpath(dir, entry.name)
              local response
              vim.ui.input({
                prompt = 'Open with: ',
                completion = 'shellcmd',
              }, function(r)
                response = r
              end)
              if not response then
                return
              end
              print('\n')
              vim.system({ response, entry_path })
            end,
          },
          ['gy'] = {
            mode = 'n',
            buffer = true,
            desc = 'Yank the filepath of the entry under the cursor to a register',
            callback = function()
              local entry = oil.get_cursor_entry()
              local dir = oil.get_current_dir()
              if not entry or not dir then
                return
              end
              local entry_path =
                vim.fn.fnamemodify(vim.fs.joinpath(dir, entry.name), ':~')
              vim.fn.setreg('"', entry_path)
              vim.fn.setreg(vim.v.register, entry_path)
              vim.notify(
                string.format(
                  "[oil.nvim] yanked '%s' to register '%s'",
                  entry_path,
                  vim.v.register
                )
              )
            end,
          },
        },
        keymaps_help = {
          border = 'solid',
        },
        float = {
          border = 'solid',
          win_options = {
            winblend = 0,
          },
        },
        preview = {
          border = 'solid',
          win_options = {
            winblend = 0,
          },
        },
        progress = {
          border = 'solid',
          win_options = {
            winblend = 0,
          },
        },
      })

      -- Override `-` to use `:Oil` to open parent dir, previously mapped in
      -- `core.keymaps`
      vim.keymap.set(
        { 'n', 'x' },
        '-',
        vim.cmd.Oil,
        { desc = "Edit current file's directory" }
      )

      -- Open project root with <leader>0
      vim.keymap.set('n', '<leader>0', function()
        local path
        if vim.bo.filetype == 'oil' then
          path = require('oil').get_current_dir()
        else
          path = vim.api.nvim_buf_get_name(0)
        end

        local root = require('utils').fs.cwd_dir(path) or vim.fn.getcwd()
        require('oil').open(root)
      end, { desc = 'Oil: Open Root', silent = true })

      local groupid = vim.api.nvim_create_augroup('oil', {})
      vim.api.nvim_create_autocmd('BufEnter', {
        desc = 'Ensure that oil buffers are not listed.',
        group = groupid,
        pattern = 'oil://*',
        callback = function(args)
          vim.bo[args.buf].buflisted = false
        end,
      })

      ---Change cwd in oil buffer to follow the directory shown in the buffer
      ---@param buf integer? default to current buffer
      local function oil_cd(buf)
        buf = vim._resolve_bufnr(buf)
        if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].ft ~= 'oil' then
          return
        end

        vim.api.nvim_buf_call(buf, function()
          local oildir = vim.fs.normalize(oil.get_current_dir() or '')
          if vim.fn.isdirectory(oildir) == 0 then
            return
          end

          for _, win in ipairs(vim.fn.win_findbuf(buf)) do
            vim.api.nvim_win_call(win, function()
              -- Always change local cwd without checking if current cwd is already
              -- `oildir`, else setting local cwd for preview window can change
              -- (global) cwd of oil buffer unexpectedly
              lcd(oildir)
            end)
          end
        end)
      end

      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        oil_cd(buf)
      end

      vim.api.nvim_create_autocmd({ 'BufEnter', 'TextChanged' }, {
        desc = 'Set cwd to follow directory shown in oil buffers.',
        group = groupid,
        pattern = 'oil://*',
        nested = true, -- fire `DirChanged` event
        callback = function(args)
          oil_cd(args.buf)
        end,
      })

      ---Record alternate file in dir buffers.
      ---@param buf? integer
      local function oil_record_alt_file(buf)
        buf = vim._resolve_bufnr(buf)
        if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].ft ~= 'oil' then
          return
        end

        if vim.fn.isdirectory(vim.api.nvim_buf_get_name(buf)) == 1 then
          vim.b[buf]._alt_file = vim.fn.bufnr('#')
        end
      end

      ---Set last cursor position in oil buffers when editing parent dir
      ---@param buf? integer
      local function oil_set_cursor(buf)
        buf = vim._resolve_bufnr(buf)
        if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].ft ~= 'oil' then
          return
        end

        -- Only set cursor position when first entering an oil buffer in current window
        -- This prevents cursor from resetting to the original file when switching
        -- between oil and preview windows, e.g.
        -- 1. Open `foo/bar.txt`
        -- 2. Run `:e %:p:h` to open `foo/` in oil - cursor starts on `bar.txt`
        -- 3. Open preview window
        -- 4. Move cursor to different files in oil buffer
        -- 5. Switch to preview window
        -- 6. Switch back to oil buffer
        -- Without this check, cursor would incorrectly reset to `bar.txt`
        -- Setting a boolean flag i.e. set `_oil_entered` to `true` or `false`
        -- is not enough because oil reuses buffers for the same directory, consider
        -- the following case:
        -- 1. `:vsplit`
        -- 2. `:e .` to open oil in one split
        -- 3. `:close`
        -- 4. `:e .` to open oil in another split (reuse oil buffer!)
        -- If we use a boolean flag for `_oil_entered`, we will not able to set cursor
        -- position in oil buffer on step 4 because the flag is set in step 2.
        local win = vim.api.nvim_get_current_win()
        if vim.b[buf]._oil_entered == win then
          return
        end
        vim.b[buf]._oil_entered = win

        -- Place cursor on the alternate buffer if we are opening
        -- the parent directory of the alternate buffer
        local alt_file = vim.fn.bufnr('#')
        if not vim.api.nvim_buf_is_valid(alt_file) then
          return
        end

        -- Because we use `:e <dir>` to open oil, the alternate file will be a dir
        -- buffer. Retrieve the "real" alternate buffer (file buffer) we recorded
        -- in the dir buffer
        local _alt_file = vim.b[alt_file]._alt_file
        if _alt_file and vim.api.nvim_buf_is_valid(_alt_file) then
          alt_file = _alt_file
        end
        local bufname_alt = vim.api.nvim_buf_get_name(alt_file)
        local parent_url, basename =
          oil.get_buffer_parent_url(bufname_alt, true)
        if basename then
          if
            not oil_config.view_options.show_hidden
            and oil_config.view_options.is_hidden_file(
              basename,
              (function()
                for _, b in ipairs(vim.api.nvim_list_bufs()) do
                  if vim.api.nvim_buf_get_name(b) == basename then
                    return b
                  end
                end
              end)()
            )
          then
            oil_view.toggle_hidden()
          end
          oil_view.set_last_cursor(parent_url, basename)
          oil_view.maybe_set_cursor()
        end
      end

      oil_record_alt_file(0)
      oil_set_cursor(0)

      vim.api.nvim_create_autocmd('BufEnter', {
        desc = 'Set last cursor position in oil buffers when editing parent dir.',
        group = groupid,
        pattern = 'oil://*',
        callback = function(args)
          oil_record_alt_file(args.buf)
          oil_set_cursor(args.buf)
        end,
      })

      require('utils.hl').persist(function()
        local hl = require('utils.hl')

        hl.set(0, 'OilDir', { fg = 'Directory' })
        hl.set(0, 'OilDirIcon', { fg = 'Directory' })
        hl.set(0, 'OilLink', { fg = 'Constant' })
        hl.set(0, 'OilLinkTarget', { fg = 'Special' })
        hl.set(0, 'OilCopy', { fg = 'DiagnosticSignHint', bold = true })
        hl.set(0, 'OilMove', { fg = 'DiagnosticSignWarn', bold = true })
        hl.set(0, 'OilChange', { fg = 'DiagnosticSignWarn', bold = true })
        hl.set(0, 'OilCreate', { fg = 'DiagnosticSignInfo', bold = true })
        hl.set(0, 'OilDelete', { fg = 'DiagnosticSignError', bold = true })
        hl.set(0, 'OilPermissionNone', { fg = 'NonText' })
        hl.set(0, 'OilPermissionRead', { fg = 'DiagnosticSignWarn' })
        hl.set(0, 'OilPermissionWrite', { fg = 'DiagnosticSignError' })
        hl.set(0, 'OilPermissionExecute', { fg = 'DiagnosticSignInfo' })
        hl.set(0, 'OilPermissionSetuid', { fg = 'DiagnosticSignHint' })
        hl.set(0, 'OilSecurityContext', { fg = 'Special' })
        hl.set(0, 'OilSecurityExtended', { fg = 'Special' })
        hl.set(0, 'OilTypeDir', { fg = 'Directory' })
        hl.set(0, 'OilTypeFifo', { fg = 'Special' })
        hl.set(0, 'OilTypeFile', { fg = 'NonText' })
        hl.set(0, 'OilTypeLink', { fg = 'Constant' })
        hl.set(0, 'OilTypeSocket', { fg = 'OilSocket' })
      end)

      ---Drag & drop files into oil buffer
      ---Source: https://github.com/HakonHarnes/img-clip.nvim/blob/main/plugin/img-clip.lua
      vim.paste = (function(cb)
        return function(lines, phase)
          if vim.bo.ft ~= 'oil' then
            cb(lines, phase)
            return
          end

          -- Don't handle streamed and multi-line paste
          if phase ~= -1 or #lines ~= 1 then
            cb(lines, phase)
            return
          end

          local uri = lines[1]
          local fname = vim.fs.basename(uri:gsub('/+$', ''))
          local buf = vim.api.nvim_get_current_buf()
          local current_dir = oil.get_current_dir()
          local dest = vim.fs.joinpath(current_dir, fname)

          ---Refresh oil buffer
          local function oil_refresh_place_cursor()
            if not vim.api.nvim_buf_is_valid(buf) then
              return
            end
            oil_view.render_buffer_async(buf, {}, function()
              if not vim.api.nvim_buf_is_valid(buf) then
                return
              end
              vim.api.nvim_buf_call(buf, function()
                oil_view.set_last_cursor(vim.api.nvim_buf_get_name(buf), fname)
                oil_view.maybe_set_cursor()
              end)
            end)
          end

          -- Paste file from web url
          if string.match(uri, '^https?://[^/]+/[^.]+') then
            require('utils.web').get(
              uri,
              dest,
              vim.schedule_wrap(function(o)
                if o.code == 0 then
                  oil_refresh_place_cursor()
                  return
                end
                vim.notify(
                  string.format(
                    "[oil.nvim] failed to fetch from '%s': %s",
                    uri,
                    o.stderr
                  ),
                  vim.log.levels.WARN
                )
              end)
            )
            return
          end

          -- Paste file from path
          local path = uri:gsub('^file://', '')
          vim.uv.fs_stat(path, function(_, stat)
            if not stat then
              vim.schedule(function()
                vim.notify(
                  string.format("[oil.nvim] invalid path: '%s'", path),
                  vim.log.levels.WARN
                )
              end)
              return
            end

            require('oil.fs').recursive_move(
              stat.type,
              path,
              dest,
              vim.schedule_wrap(function(err)
                if not err then
                  oil_refresh_place_cursor()
                  return
                end
                vim.notify(
                  string.format(
                    "[oil.nvim] failed to move from '%s' to '%s': %s",
                    path,
                    dest,
                    err
                  ),
                  vim.log.levels.WARN
                )
              end)
            )
          end)
        end
      end)(vim.paste)
    end,
  },
}
