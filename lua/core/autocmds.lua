---@param group string
---@vararg { [1]: string|string[], [2]: vim.api.keyset.create_autocmd }
---@return nil
local function augroup(group, ...)
  local id = vim.api.nvim_create_augroup(group, {})
  for _, a in ipairs({ ... }) do
    a[2].group = id
    vim.api.nvim_create_autocmd(unpack(a))
  end
end

do
  vim.g.bigfile_max_size = vim.g.bigfile_max_size or 1048576
  vim.g.bigfile_max_lines = vim.g.bigfile_max_lines or 32768

  augroup('bigfile', {
    'BufReadPre',
    {
      desc = 'Detect big files.',
      callback = function(args)
        local stat = vim.uv.fs_stat(args.match)
        if stat and stat.size > vim.g.bigfile_max_size then
          vim.b[args.buf].bigfile = true
        end
      end,
    },
  }, {
    { 'BufEnter', 'TextChanged', 'CmdWinEnter' },
    {
      desc = 'Detect big files.',
      callback = function(args)
        local buf = args.buf
        if vim.b[buf].bigfile then
          return
        end

        if vim.api.nvim_buf_line_count(buf) > vim.g.bigfile_max_lines then
          vim.b[buf].bigfile = true
        end
      end,
    },
  }, {
    'FileType',
    {
      once = true,
      desc = 'Prevent treesitter from attaching to big files.',
      callback = function(args)
        vim.api.nvim_del_autocmd(args.id)

        local ts_get_parser = vim.treesitter.get_parser
        local ts_foldexpr = vim.treesitter.foldexpr

        ---@diagnostic disable-next-line: duplicate-set-field
        function vim.treesitter.get_parser(buf, ...)
          buf = vim._resolve_bufnr(buf)
          if vim.api.nvim_buf_is_valid(buf) and vim.b[buf].bigfile then
            return vim.treesitter._create_parser(
              vim.api.nvim_create_buf(false, true),
              vim.treesitter.language.get_lang(vim.bo.ft) or vim.bo.ft
            )
          end
          return ts_get_parser(buf, ...)
        end

        ---@diagnostic disable-next-line: duplicate-set-field
        function vim.treesitter.foldexpr(...)
          if vim.b.bigfile then
            return
          end
          return ts_foldexpr(...)
        end
      end,
    },
  }, {
    'BufReadPre',
    {
      desc = 'Disable options in big files.',
      callback = function(args)
        local buf = args.buf
        if not vim.b[buf].bigfile then
          return
        end
        vim.api.nvim_buf_call(buf, function()
          vim.opt_local.spell = false
          vim.opt_local.swapfile = false
          vim.opt_local.undofile = false
          vim.opt_local.breakindent = false
          vim.opt_local.foldmethod = 'manual'
        end)
      end,
    },
  }, {
    { 'TextChanged', 'FileType' },
    {
      desc = 'Stop treesitter in big files.',
      callback = function(args)
        local buf = args.buf
        if vim.b[buf].bigfile and require('utils.ts').is_active(buf) then
          vim.treesitter.stop(buf)
          vim.bo[buf].syntax = 'ON'
        end
      end,
    },
  })
end

augroup('yank_highlight', {
  'TextYankPost',
  {
    desc = 'Highlight the selection on yank.',
    callback = function()
      pcall(vim.highlight.on_yank, {
        higroup = 'Visual',
        timeout = 250,
      })
    end,
  },
})

augroup('auto_save', {
  { 'BufLeave', 'WinLeave', 'FocusLost' },
  {
    nested = true,
    desc = 'Autosave on focus change.',
    callback = function(args)
      vim.uv.fs_stat(args.file, function(err, stat)
        if err or not stat or stat.type ~= 'file' then
          return
        end
        vim.schedule(function()
          if not vim.api.nvim_buf_is_valid(args.buf) then
            return
          end
          vim.api.nvim_buf_call(args.buf, function()
            vim.cmd.update({
              mods = { emsg_silent = true },
            })
          end)
        end)
      end)
    end,
  },
})

augroup('win_close_jmp', {
  'WinClosed',
  {
    nested = true,
    desc = 'Jump to last accessed window on closing the current one.',
    command = "if expand('<amatch>') == win_getid() | wincmd p | endif",
  },
})

augroup('last_pos_jmp', {
  'BufReadPre',
  {
    desc = 'Last position jump.',
    callback = function(args)
      if vim.b[args.buf].lpj then
        return
      end
      vim.b[args.buf].lpj = true

      vim.api.nvim_create_autocmd('FileType', {
        once = true,
        buffer = args.buf,
        callback = function(a)
          local ft = vim.bo[a.buf].ft
          if ft == 'gitcommit' or ft == 'gitrebase' then
            return
          end
          local last_pos = vim.api.nvim_buf_get_mark(a.buf, '"')
          if vim.deep_equal(last_pos, { 0, 0 }) then
            return
          end
          for _, win in ipairs(vim.fn.win_findbuf(a.buf)) do
            pcall(vim.api.nvim_win_set_cursor, win, last_pos)
          end
        end,
      })
    end,
  },
})

do
  augroup('auto_cwd', {
    'BufEnter',
    {
      desc = 'Automatically change local current directory.',
      nested = true,
      callback = function(args)
        local file = args.file
        local buf = args.buf

        if file == '' or vim.bo[buf].bt ~= '' then
          return
        end

        local fs_utils = require('utils.fs')
        local root_dir =
          fs_utils.root(file, vim.b.root_markers or fs_utils.root_markers)

        if
          not root_dir
          or fs_utils.is_home_dir(root_dir)
          or fs_utils.is_root_dir(root_dir)
        then
          root_dir = vim.fs.dirname(file)
        end

        if not root_dir then
          return
        end

        for _, win in ipairs(vim.fn.win_findbuf(buf)) do
          vim.api.nvim_win_call(win, function()
            if root_dir == vim.fn.getcwd(0) then
              return
            end
            pcall(vim.cmd.lcd, {
              root_dir,
              mods = {
                silent = true,
                emsg_silent = true,
              },
            })
          end)
        end
      end,
    },
  })
end

augroup('prompt_keymaps', {
  'BufEnter',
  {
    desc = 'Undo automatic <C-w> remap in prompt buffers.',
    callback = function(args)
      if vim.bo[args.buf].buftype == 'prompt' then
        vim.keymap.set('i', '<C-w>', '<C-S-W>', { buffer = args.buf })
      end
    end,
  },
})

do
  local win_ratio = {}
  augroup('keep_win_ratio', {
    { 'VimResized', 'TabEnter' },
    {
      desc = 'Keep window ratio after resizing nvim.',
      callback = function()
        vim.g._vim_resized = true
        vim.api.nvim_create_autocmd('WinResized', {
          once = true,
          callback = function()
            vim.g._vim_resized = nil
          end,
        })
        require('utils.win').restore_ratio(win_ratio)
      end,
    },
  }, {
    'WinResized',
    {
      desc = 'Record window ratio.',
      callback = function()
        if vim.g._vim_resized then
          return
        end
        require('utils.win').save_ratio(win_ratio, vim.v.event.windows)
      end,
    },
  }, {
    { 'TermOpen', 'WinNew' },
    {
      desc = 'Record window ratio.',
      callback = function()
        require('utils.win').save_ratio(win_ratio, vim.api.nvim_list_wins())
      end,
    },
  })
end

do
  local win_heights = {}

  local function win_save_fixed_heights()
    require('utils.win').save_heights(
      win_heights,
      vim
        .iter(vim.api.nvim_tabpage_list_wins(0))
        :filter(function(win)
          return vim.wo[win].winfixheight
        end)
        :totable()
    )
  end

  augroup('fix_winfixheight_with_winbar', {
    { 'WinNew', 'WinClosed' },
    {
      desc = 'Save heights for windows with a fixed height.',
      callback = function()
        vim.g._win_list_changed = true
        vim.schedule(function()
          vim.g._win_list_changed = nil
        end)

        vim.schedule(win_save_fixed_heights)
      end,
    },
  }, {
    'OptionSet',
    {
      desc = 'Save heights for windows with a fixed height.',
      pattern = 'winfixheight',
      callback = win_save_fixed_heights,
    },
  }, {
    'WinResized',
    {
      desc = 'Restore heights for windows with a fixed height.',
      callback = function()
        if not vim.g._win_list_changed then
          win_save_fixed_heights()
          return
        end
        require('utils.win').restore_heights(win_heights)
      end,
    },
  }, {
    'FileType',
    {
      desc = 'Set quickfix window initial height.',
      pattern = 'qf',
      callback = function(args)
        vim.api.nvim_win_set_height(vim.fn.bufwinid(args.buf), 10)
      end,
    },
  })
end

augroup('fix_cmdline_iskeyword', {
  'CmdLineEnter',
  {
    desc = 'Have consistent &iskeyword and &lisp in Ex command-line mode.',
    pattern = '[:>/?=@]',
    callback = function(args)
      vim.g._isk_lisp_buf = args.buf
      vim.g._isk_save = vim.bo[args.buf].isk
      vim.g._lisp_save = vim.bo[args.buf].lisp
      vim.cmd.setlocal('isk&')
      vim.cmd.setlocal('lisp&')
    end,
  },
}, {
  'CmdLineLeave',
  {
    desc = 'Restore &iskeyword after leaving command-line mode.',
    pattern = '[:>/?=@]',
    callback = function()
      if
        vim.g._isk_lisp_buf
        and vim.api.nvim_buf_is_valid(vim.g._isk_lisp_buf)
        and vim.g._isk_save ~= vim.b[vim.g._isk_lisp_buf].isk
      then
        vim.bo[vim.g._isk_lisp_buf].isk = vim.g._isk_save
        vim.bo[vim.g._isk_lisp_buf].lisp = vim.g._lisp_save
        vim.g._isk_save = nil
        vim.g._lisp_save = nil
        vim.g._isk_lisp_buf = nil
      end
    end,
  },
})

augroup('dynamic_cc', {
  { 'BufNew', 'BufEnter' },
  {
    desc = 'Set `colorcolumn` to follow `textwidth` in new buffers.',
    callback = function(args)
      if vim.bo[args.buf].tw == 0 then
        return
      end

      for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
        if vim.wo[win].cc == '' or vim.wo[win].cc:find('+', 1, true) then
          goto continue
        end
        vim.b[args.buf].cc = vim.wo[win].cc
        vim.wo[win][0].cc = '+1'
        ::continue::
      end
    end,
  },
}, {
  'OptionSet',
  {
    desc = 'Set `colorcolumn` to follow `textwidth` when `textwidth` is set.',
    pattern = 'textwidth',
    callback = function()
      if vim.v.option_command == 'setglobal' then
        return
      end

      local cc_is_relative = vim.wo.cc:find('+', 1, true)
      local wins = vim.fn.win_findbuf(vim.api.nvim_get_current_buf())

      if vim.v.option_new > 0 and not cc_is_relative then
        vim.b.cc = vim.wo.cc
        for _, win in ipairs(wins) do
          if vim.wo[win].cc ~= '' then
            vim.wo[win][0].cc = '+1'
          end
        end
        return
      end

      if vim.v.option_new == 0 and cc_is_relative and vim.b.cc then
        for _, win in ipairs(wins) do
          if vim.wo.cc ~= '' then
            vim.wo[win][0].cc = vim.b.cc
          end
        end
        vim.b.cc = nil
      end
    end,
  },
})

do
  local hl = require('utils.hl')

  hl.persist(function()
    local hl_utils = require('utils.hl')
    local normal = hl_utils.get(0, { name = 'Normal', winhl_link = false })
    local float_border =
      hl_utils.get(0, { name = 'FloatBorder', winhl_link = false })
    if
      not normal
      or not normal.bg
      or not float_border
      or not float_border.bg
    then
      return
    end
    local blended_bg = hl_utils.cblend(normal.bg, float_border.bg, 0.5).dec
    hl.set(
      0,
      'NormalSpecial',
      vim.tbl_deep_extend(
        'force',
        { default = true },
        { fg = normal.fg, bg = blended_bg }
      )
    )
  end)

  augroup('special_buf_hl', {
    { 'BufEnter', 'BufNew', 'FileType', 'TermOpen' },
    {
      desc = 'Set background color for special buffers.',
      callback = vim.schedule_wrap(function(args)
        local buf = args.buf
        if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].bt == '' then
          return
        end
        local winid = vim.fn.bufwinid(buf)
        if winid == -1 then
          return
        end
        local wintype = vim.fn.win_gettype(winid)
        if wintype == 'popup' or wintype == 'autocmd' then
          return
        end
        vim.api.nvim_win_call(winid, function()
          if vim.opt_local.winhighlight:get().Normal then
            return
          end
          vim.opt_local.winhighlight:append({
            Normal = 'NormalSpecial',
            EndOfBuffer = 'NormalSpecial',
          })

          vim.opt_local.number = false
          vim.opt_local.relativenumber = false
          vim.opt_local.signcolumn = 'no' -- Removes the gutter on the left
          vim.opt_local.fillchars:append({ eob = ' ' })
        end)
      end),
    },
  })
end

do
  local function win_is_normal(win)
    return vim.fn.win_gettype(win) == ''
  end

  local function tabpage_list_normal_wins(tab)
    return vim
      .iter(vim.api.nvim_tabpage_list_wins(tab))
      :filter(win_is_normal)
      :totable()
  end

  augroup('session_wipe_empty_bufs', {
    'SessionLoadPost',
    {
      desc = 'Wipe empty buffers after loading session.',
      nested = true,
      callback = function()
        local whitelist = {} ---@type table<integer, true>

        for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
          local buf = nil ---@type integer?

          for _, win in ipairs(tabpage_list_normal_wins(tab)) do
            local win_buf = vim.api.nvim_win_get_buf(win)
            buf = buf or win_buf
            if buf ~= win_buf then
              goto continue
            end
          end

          if buf then
            whitelist[buf] = true
          end
          ::continue::
        end

        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if whitelist[buf] or not require('utils.buf').is_empty(buf) then
            goto continue
          end
          local bufname = vim.api.nvim_buf_get_name(buf)
          if bufname:match('://') then
            goto continue
          end
          if not vim.uv.fs_stat(bufname) then
            pcall(vim.api.nvim_buf_delete, buf, {})
          end
          ::continue::
        end
      end,
    },
  })
end

do
  local json = require('utils.json')

  local colors_config_file =
    vim.fs.joinpath(vim.fn.stdpath('state'), 'colors.json')

  local function restore_colorscheme()
    local colors_config = vim.tbl_deep_extend(
      'keep',
      json.read(colors_config_file),
      { bg = 'dark', colors_name = 'nano' }
    )

    vim.go.bg = colors_config.bg

    if vim.v.vim_did_enter == 1 then
      vim.cmd.colorscheme({
        args = { colors_config.colors_name },
        mods = { emsg_silent = true },
      })
    end
  end

  restore_colorscheme()

  augroup('colorscheme_restore', {
    'UIEnter',
    {
      nested = true,
      callback = restore_colorscheme,
    },
  }, {
    'OptionSet',
    {
      nested = true,
      pattern = 'termguicolors',
      callback = restore_colorscheme,
    },
  }, {
    'Colorscheme',
    {
      nested = true,
      desc = 'Spawn setbg/setcolors on colorscheme change.',
      callback = function()
        if vim.g.script_set_bg or vim.g.script_set_colors then
          return
        end

        vim.schedule(function()
          local colors_config = json.read(colors_config_file)

          if
            colors_config.colors_name == vim.g.colors_name
            and colors_config.bg == vim.go.bg
          then
            return
          end

          if colors_config.colors_name ~= vim.g.colors_name then
            colors_config.colors_name = vim.g.colors_name
            if vim.fn.executable('setcolor') == 1 then
              vim.system({ 'setcolor', vim.g.colors_name })
            end
          end

          if colors_config.bg ~= vim.go.bg and vim.go.termguicolors then
            colors_config.bg = vim.go.bg
            if vim.fn.executable('setbg') == 1 then
              vim.system({ 'setbg', vim.go.bg })
            end
          end

          json.write(colors_config_file, colors_config)
        end)
      end,
    },
  })
end

augroup('auto_formatoptions', {
  'BufEnter',
  {
    desc = 'Disable New Line Comment',
    callback = function()
      vim.opt.formatoptions:remove({ 'c', 'r', 'o' })
    end,
  },
})

augroup('highlight_url', {
  { 'VimEnter', 'FileType', 'BufEnter', 'WinEnter' },
  {
    desc = 'Highlight URLs',
    callback = function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        require('utils.general').set_url_match(win)
      end
    end,
  },
})

local q_close_group =
  vim.api.nvim_create_augroup('QCloseSpecial', { clear = true })
vim.api.nvim_create_autocmd('BufWinEnter', {
  group = q_close_group,
  callback = function(event)
    -- If the window is floating (relative is not empty), map 'q'
    local win_config = vim.api.nvim_win_get_config(0)
    if win_config.relative ~= '' then
      vim.keymap.set(
        'n',
        'q',
        '<cmd>close<cr>',
        { buffer = event.buf, silent = true }
      )
    end
  end,
})

augroup('terminal_clean_exit', {
  'VimLeavePre',
  {
    desc = 'Force close all terminal buffers on exit to prevent hang',
    callback = function()
      local buffers = vim.api.nvim_list_bufs()
      for _, buf in ipairs(buffers) do
        if vim.bo[buf].buftype == 'terminal' then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end
    end,
  },
})

augroup('terminal_settings', {
  'TermOpen',
  {
    desc = 'Set terminal buffer options',
    callback = function()
      vim.opt_local.confirm = false
      vim.bo.modified = false
    end,
  },
})

augroup('auto_center', {
  { 'CmdLineLeave', 'WinEnter' },
  {
    desc = 'Center cursor after commands',
    callback = function()
      if vim.api.nvim_get_mode().mode == 'i' or vim.bo.buftype ~= '' then
        return
      end
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(0) then
          pcall(vim.cmd.normal, { 'zz', bang = true })
        end
      end)
    end,
  },
})

augroup('substitute_notify', {
  'CmdlineLeave',
  {
    desc = 'Notify number of changes after substitute',
    callback = function(ctx)
      if not ctx.match == ':' then
        return
      end
      local cmdline = vim.fn.getcmdline()
      local isSubstitution = cmdline:find('s ?/.+/.-/%a*$')
      if isSubstitution then
        vim.cmd(cmdline .. 'ne')
      end
    end,
  },
})

augroup('quickfix_auto_open', {
  'QuickFixCmdPost',
  {
    desc = 'Open quickfix window if there are results.',
    callback = function(info)
      if #vim.fn.getqflist() > 1 then
        vim.schedule(vim.cmd[info.match:find('^l') and 'lwindow' or 'cwindow'])
      end
    end,
  },
})

augroup('cleanup_no_name', {
  'BufHidden',
  {
    desc = 'Delete [No Name] buffers when they are no longer displayed',
    callback = function(data)
      if
        data.file == ''
        and vim.bo[data.buf].buftype == ''
        and not vim.bo[data.buf].modified
      then
        vim.schedule(function()
          if
            vim.api.nvim_buf_is_valid(data.buf)
            and vim.fn.bufwinid(data.buf) == -1
          then
            pcall(vim.api.nvim_buf_delete, data.buf, { force = false })
          end
        end)
      end
    end,
  },
})

augroup('statusline_redraw', {
  { 'FileChangedShellPost', 'DiagnosticChanged', 'LspProgress' },
  {
    desc = 'Redraw statusline on changes',
    callback = function()
      vim.cmd('redrawstatus')
    end,
  },
})

augroup('git_work_tree_refresh', {
  { 'BufEnter', 'FocusGained' },
  {
    desc = 'Clear git work tree cache',
    callback = function()
      vim.b.git_work_tree = nil
      vim.b.git_dir = nil
    end,
  },
})

augroup('unlist_quickfix', {
  'FileType',
  {
    desc = 'Unlist quickfix buffers',
    pattern = 'qf',
    callback = function()
      vim.opt_local.buflisted = false
    end,
  },
})

augroup('fix_virtual_edit_cursor', {
  'CursorMoved',
  {
    desc = 'Record cursor position in visual mode if virtualedit is set.',
    callback = function()
      if vim.wo.ve:find('all') then
        vim.w.ve_cursor = vim.fn.getcurpos()
      end
    end,
  },
})

augroup('cleanup_history', {
  'CmdlineLeave',
  {
    desc = 'Clean up line-jump from command history',
    callback = function(ctx)
      if not ctx.match == ':' then
        return
      end
      vim.defer_fn(function()
        local lineJump = vim.fn.histget(':', -1):match('^%d+$')
        if lineJump then
          vim.fn.histdel(':', -1)
        end
      end, 100)
    end,
  },
})

augroup('auto_delete_dirs', {
  'FocusLost',
  {
    once = true,
    desc = 'Clean up old view and undo directories',
    callback = function()
      if os.date('%a') == 'Mon' then
        vim.fn.system({
          'find',
          vim.opt.viewdir:get(),
          '-mtime',
          '+60d',
          '-delete',
        })
        vim.fn.system({
          'find',
          vim.opt.undodir:get()[1],
          '-mtime',
          '+30d',
          '-delete',
        })
      end
    end,
  },
})

local group = vim.api.nvim_create_augroup('WinCloseJmp', { clear = true })
vim.api.nvim_create_autocmd('WinClosed', {
  group = group,
  nested = true,
  desc = 'Jump to last accessed window on closing the current one.',
  callback = function(args)
    -- args.match contains the window ID being closed
    local closed_win = tonumber(args.match)
    if closed_win == vim.api.nvim_get_current_win() then
      vim.cmd('wincmd p')
    end
  end,
})

augroup('change_to_cur_dir', {
  { 'FileChangedShellPost', 'BufWinEnter' },
  {
    desc = 'Automatically change local current directory.',
    callback = function(info)
      if
        info.file == ''
        or info.file:match('://')
        or vim.bo[info.buf].bt ~= ''
      then
        return
      end

      local buf = info.buf
      local win = vim.api.nvim_get_current_win()

      vim.schedule(function()
        if
          not vim.api.nvim_buf_is_valid(buf)
          or not vim.api.nvim_win_is_valid(win)
          or vim.api.nvim_win_get_buf(win) ~= buf
        then
          return
        end

        vim.api.nvim_win_call(win, function()
          local current_dir = vim.fn.getcwd(0)
          local project_root = require('utils.fs').cwd_dir(info.file)
          local target_dir = project_root or vim.fs.dirname(info.file)

          if target_dir then
            local stat = vim.uv.fs_stat(target_dir)
            if
              stat
              and stat.type == 'directory'
              and current_dir ~= target_dir
            then
              vim.notify_once('cd to ' .. target_dir)
              pcall(vim.cmd.lcd, target_dir)
            end
          end
        end)
      end)
    end,
  },
})
