---@type pack.spec
return {
  src = "https://github.com/ibhagwan/fzf-lua",
  data = {
    lazy = false,
    deps = {
      {
        src = "https://github.com/kyazdani42/nvim-web-devicons",
        data = { optional = true },
      },
    },
    cmds = "FzfLua",
    init = function(spec, path)
      -- Disable fzf's default vim plugin
      vim.g.loaded_fzf = 1

      local ui_select = vim.ui.select

      local function setup_ui_select()
        ---@diagnostic disable-next-line: duplicate-set-field
        vim.ui.select = function(...)
          if vim.fn.executable "fzf" == 0 then
            vim.ui.select = ui_select
            vim.ui.select(...)
            return
          end

          require("utils.pack").load(spec, path)

          local fzf_ui = require "fzf-lua.providers.ui_select"
          -- Register fzf as custom `vim.ui.select()` function if not yet
          -- registered
          if not fzf_ui.is_registered() then
            local fzf_ui_select = fzf_ui.ui_select

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
              opts.prompt = opts.prompt
                and vim.fn.substitute(
                  opts.prompt,
                  ":\\?\\s*$",
                  ":\xc2\xa0",
                  ""
                )
              fzf_ui_select(items, opts, on_choice)
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
              local n_items = #items
              local split = require("fzf-lua.config").setup_opts.winopts.split
              if type(split) == "function" then
                return { winopts = { split = split } }
              end
              if type(split) == "string" and split ~= "" then
                return {
                  winopts = {
                    split = string.format(
                      -- Don't shrink size if a quickfix list is closed for fzf
                      -- window to avoid window resizing and content shifting
                      "let g:_fzf_n_items =%d | %s | unlet g:_fzf_n_items",
                      n_items,
                      vim.trim(split)
                    ),
                  },
                }
              end
              return {
                winopts = {
                  height = math.min(10, n_items + 1),
                  row = 1,
                  col = 0,
                  width = 1,
                  preview = { hidden = true },
                },
              }
            end)
          end

          vim.ui.select(...)
        end
      end

      if vim.v.vim_did_enter == 1 then
        setup_ui_select()
      else
        vim.api.nvim_create_autocmd("UIEnter", {
          once = true,
          callback = vim.schedule_wrap(setup_ui_select),
        })
      end
    end,
    postload = function()
      if vim.fn.executable "fzf" == 0 then
        vim.notify("[Fzf-lua] command `fzf` not found", vim.log.levels.ERROR)
        return
      end

      local fzf = require "fzf-lua"
      local actions = require "fzf-lua.actions"
      local core = require "fzf-lua.core"
      local path = require "fzf-lua.path"
      local config = require "fzf-lua.config"
      local fzf_utils = require "fzf-lua.utils"
      local utils = require "utils"
      local icons = require "utils.static.icons"

      local _arg_del = actions.arg_del
      local _vimcmd_buf = actions.vimcmd_buf

      ---@diagnostic disable-next-line: duplicate-set-field
      function actions.arg_del(...)
        pcall(_arg_del, ...)
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      function actions.vimcmd_buf(...)
        pcall(_vimcmd_buf, ...)
      end

      ---Switch provider while preserving the last query and cwd
      ---@return nil
      function actions.switch_provider()
        local opts = {
          query = fzf.config.__resume_data.last_query,
          cwd = fzf.config.__resume_data.opts.cwd,
        }
        ---@diagnostic disable-next-line: missing-fields
        fzf.builtin {
          actions = {
            ["enter"] = function(selected)
              fzf[selected[1]](opts)
            end,
            ["esc"] = actions.resume,
          },
        }
      end

      -- Shared state between file-like pickers and grep mode for cumulative
      -- filtering.
      local _toggle_state = {
        files_query = "",
        grep_query = "",
        source_key = nil,
        source_opts = nil,
        listfile = nil,
        file_count = 0,
        file_limited = false,
      }

      local toggle_file_limit = tonumber(vim.g.fzf_lua_toggle_file_limit)
        or 20000

      local function shellescape(value)
        return vim.fn.shellescape(value or "")
      end

      local function display_query(query)
        return query ~= "" and query or "<empty>"
      end

      local preview_hint = "preview: F4/F5 | scroll: C-f/C-b"

      local function preview_header(header)
        return header and header ~= "" and header .. " | " .. preview_hint
          or preview_hint
      end

      local function home_path(pathname)
        if type(pathname) ~= "string" or pathname == "" then
          return pathname
        end
        return vim.fn.fnamemodify(pathname, ":~")
      end

      local function reverse_list(items)
        local reversed = {}
        for i = #items, 1, -1 do
          table.insert(reversed, items[i])
        end
        return reversed
      end

      local function with_toggle_header(opts, parts)
        opts = vim.deepcopy(opts or {})
        opts.fzf_opts = vim.tbl_deep_extend("force", opts.fzf_opts or {}, {
          ["--header-first"] = true,
        })
        opts.header = preview_header(table.concat(parts, " | "))
        return opts
      end

      local function cleanup_toggle_list()
        if _toggle_state.listfile then
          vim.fn.delete(_toggle_state.listfile)
          _toggle_state.listfile = nil
        end
        _toggle_state.file_count = 0
        _toggle_state.file_limited = false
      end

      ---@param listfile string
      ---@return integer
      local function listfile_count(listfile)
        local output = vim.fn.system { "wc", "-l", listfile }
        return tonumber(output:match "^%s*(%d+)") or 0
      end

      ---@return string
      local function toggle_scope_header()
        if _toggle_state.file_count <= 0 then
          return "scope: <empty>"
        end
        local limit = _toggle_state.file_limited and "+" or ""
        return ("scope: %d%s files"):format(_toggle_state.file_count, limit)
      end

      ---@param listfile string
      ---@return function
      local function files_from_list_grep_cmd(listfile)
        local escaped_listfile = shellescape(listfile)

        return function(search_query, command)
          command = command:gsub("%s%-e%s*$", "")
          if not command:find("--with-filename", 1, true) then
            command = command .. " --with-filename"
          end
          return string.format(
            "test -s %s && [ -n %s ] && tr '\\n' '\\0' < %s | xargs -0 -n 200 %s -e %s --",
            escaped_listfile,
            search_query,
            escaped_listfile,
            command,
            search_query
          ),
            search_query
        end
      end

      ---@param listfile string
      ---@param cwd string?
      ---@return table
      local function list_grep_opts(listfile, cwd)
        _toggle_state.file_count = listfile_count(listfile)
        _toggle_state.file_limited = _toggle_state.file_count
          >= toggle_file_limit
        return {
          cwd = cwd,
          exec_empty_query = false,
          fn_transform_cmd = files_from_list_grep_cmd(listfile),
          query = _toggle_state.grep_query,
          rg_glob = false,
        }
      end

      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = cleanup_toggle_list,
        desc = "Clean fzf-lua files/grep toggle file list",
      })

      ---@param files string[]
      ---@param query string
      ---@return string?
      local function write_filtered_file_list(files, query)
        cleanup_toggle_list()

        if #files == 0 then
          return nil
        end
        if #files > toggle_file_limit then
          files = vim.list_slice(files, 1, toggle_file_limit)
        end

        local listfile = vim.fn.tempname()
        vim.fn.writefile(files, listfile)

        if query ~= "" then
          local filtered = vim.fn.tempname()
          local result = vim
            .system({
              "sh",
              "-c",
              string.format(
                "fzf --filter %s < %s > %s",
                shellescape(query),
                shellescape(listfile),
                shellescape(filtered)
              ),
            })
            :wait()
          vim.fn.delete(listfile)
          listfile = filtered
          if result.code ~= 0 then
            vim.fn.delete(listfile)
            return nil
          end
        end

        if listfile_count(listfile) > toggle_file_limit then
          local limited = vim.fn.tempname()
          local result = vim
            .system({
              "sh",
              "-c",
              string.format(
                "awk 'NR <= %d { print } NR > %d { exit }' %s > %s",
                toggle_file_limit,
                toggle_file_limit,
                shellescape(listfile),
                shellescape(limited)
              ),
            })
            :wait()
          vim.fn.delete(listfile)
          listfile = limited
          if result.code ~= 0 then
            vim.fn.delete(listfile)
            return nil
          end
        end

        _toggle_state.listfile = listfile
        return listfile
      end

      ---@param cmd string
      ---@param query string
      ---@param cwd string?
      ---@return string?
      local function write_filtered_file_list_from_cmd(cmd, query, cwd)
        cleanup_toggle_list()

        local listfile = vim.fn.tempname()
        local filter = query ~= ""
            and string.format(" | fzf --filter %s", shellescape(query))
          or ""
        local result = vim
          .system({
            "sh",
            "-c",
            string.format(
              "(%s)%s | awk 'NR <= %d { print } NR > %d { exit }' > %s",
              cmd,
              filter,
              toggle_file_limit,
              toggle_file_limit,
              shellescape(listfile)
            ),
          }, { cwd = cwd })
          :wait()

        if result.code ~= 0 then
          vim.fn.delete(listfile)
          return nil
        end

        _toggle_state.listfile = listfile
        return listfile
      end

      ---@param cwd string
      ---@return string[]
      local function listed_buffer_files(cwd)
        local files = {}
        local seen = {}

        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          local name = vim.api.nvim_buf_get_name(bufnr)
          if
            name ~= ""
            and vim.fn.filereadable(name) == 1
            and not seen[name]
          then
            seen[name] = true
            table.insert(files, path.relative_to(name, cwd))
          end
        end

        return files
      end

      ---@param cwd string
      ---@return string[]
      local function oldfile_entries(cwd)
        local files = {}
        local seen = {}

        for _, name in ipairs(vim.v.oldfiles or {}) do
          if
            type(name) == "string"
            and name ~= ""
            and vim.fn.filereadable(name) == 1
            and not seen[name]
          then
            seen[name] = true
            table.insert(files, path.relative_to(name, cwd))
          end
        end

        return files
      end

      ---@return string[]
      local function argfiles()
        local files = {}
        for i = 0, vim.fn.argc() - 1 do
          local name = vim.fn.argv(i)
          if type(name) == "string" and name ~= "" then
            table.insert(files, name)
          end
        end
        return files
      end

      ---Toggle between files and live_grep picker preserving queries
      ---between modes for cumulative filtering
      ---@return nil
      function actions.toggle_files_grep()
        local resume = fzf.config.__resume_data
        if not resume or not resume.opts then
          return
        end
        local key = resume.opts.__smart_files and "smart_files"
          or resume.opts.__resume_key
        local query = resume.last_query or ""
        local cwd = resume.opts.cwd or vim.fn.getcwd(0)

        if key == "files" or key == "smart_files" then
          _toggle_state.files_query = query
          _toggle_state.source_key = key
          _toggle_state.source_opts = vim.deepcopy(resume.opts)

          if query == "" then
            fzf.live_grep(with_toggle_header({
              query = _toggle_state.grep_query,
              cwd = cwd,
            }, {
              "files: " .. display_query(_toggle_state.files_query),
              "grep: " .. display_query(_toggle_state.grep_query),
              "scope: cwd",
            }))
            return
          end

          local listfile =
            write_filtered_file_list_from_cmd(resume.opts.cmd, query, cwd)
          if not listfile then
            return
          end

          local grep_opts = with_toggle_header(list_grep_opts(listfile, cwd), {
            "files: " .. display_query(_toggle_state.files_query),
            "grep: " .. display_query(_toggle_state.grep_query),
            toggle_scope_header(),
          })
          fzf.live_grep(grep_opts)
        elseif key == "buffers" or key == "oldfiles" or key == "args" then
          local files = key == "buffers" and listed_buffer_files(cwd)
            or key == "oldfiles" and oldfile_entries(cwd)
            or argfiles()
          local listfile = write_filtered_file_list(files, query)
          if not listfile then
            return
          end

          _toggle_state.files_query = query
          _toggle_state.source_key = key
          _toggle_state.source_opts = vim.deepcopy(resume.opts)
          fzf.live_grep(with_toggle_header(list_grep_opts(listfile, cwd), {
            key .. ": " .. display_query(_toggle_state.files_query),
            "grep: " .. display_query(_toggle_state.grep_query),
            toggle_scope_header(),
          }))
        elseif key == "live_grep" or key == "grep" then
          _toggle_state.grep_query = query
          local source_key = _toggle_state.source_key or "files"
          local source_opts = _toggle_state.source_opts or {}
          cleanup_toggle_list()
          source_opts.query = _toggle_state.files_query
          source_opts.resume = true
          source_opts = with_toggle_header(source_opts, {
            source_key .. ": " .. display_query(_toggle_state.files_query),
            "grep: " .. display_query(_toggle_state.grep_query),
          })
          local source = fzf[source_key] or fzf.files
          source(source_opts)
        end
      end

      local function extension_query(query)
        local token = vim.trim(query or ""):match "%S+$" or ""
        token = token:gsub("^'", ""):gsub("%$$", ""):gsub("^%*+", "")
        token = token:match "%.([^./]+)$" or token:gsub("^%.", "")
        if token == "" then
          return query
        end
        return "." .. token .. "$"
      end

      ---Strictly filter the current file-like picker by extension.
      ---@return nil
      function actions.filter_extension()
        local resume = fzf.config.__resume_data
        if not resume or not resume.opts then
          return
        end

        local key = resume.opts.__smart_files and "smart_files"
          or resume.opts.__resume_key
        local opts = vim.deepcopy(resume.opts)
        opts.query = extension_query(resume.last_query or opts.query or "")
        opts.resume = true

        local source = fzf[key] or fzf.files
        source(opts)
      end

      ---Change cwd while preserving the last query
      ---@return nil
      function actions.change_cwd()
        local resume_data =
          vim.tbl_deep_extend("force", fzf.config.__resume_data, {
            opts = {},
          })
        local opts = resume_data.opts

        local cwd = opts.cwd or vim.fn.getcwd(0)
        local cwd_in_home = utils.fs.contains("~", cwd)
        local cwd_root = cwd_in_home and "~/" or "/"

        fzf.files {
          cwd_prompt = false,
          prompt = "New cwd: " .. cwd_root,
          cwd = cwd_root,
          query = vim.fn
            .fnamemodify(cwd, cwd_in_home and ":~" or ":p")
            :gsub("^~", "")
            :gsub("^/", ""),
          -- Append current dir './' to the result list to allow switching to home
          -- or root directory
          cmd = string.format(
            "%s | sed '1i\\\n./\n'",
            (function()
              local fd_cmd = vim.fn.executable "fd" == 1 and "fd"
                or vim.fn.executable "fdfind" == 1 and "fdfind"
                or nil

              if not fd_cmd then
                return [[find -L * -type d -print0 | xargs -0 ls -Fd]]
              end

              local grep_cmd = vim.fn.executable "rg" == 1 and "rg" or "grep"
              return string.format(
                [[%s --hidden --follow --type d --type l | %s /$]],
                fd_cmd,
                grep_cmd
              )
            end)()
          ),
          fzf_opts = { ["--no-multi"] = true },
          actions = {
            -- Open the same picker with selected new cwd but keep old query
            ["enter"] = function(selected)
              if not selected[1] then
                return
              end

              -- Remove old fn_selected, else selected item will be opened
              -- with previous cwd
              opts.fn_selected = nil
              opts.resume = true
              opts.query = resume_data.last_query
              opts.cwd = vim.fs.normalize(
                vim.fs.joinpath(
                  cwd_root,
                  path.entry_to_file(selected[1], {}, false).path
                )
              )

              -- Adapted from fzf-lua `core.set_header()` function
              if opts.cwd_prompt then
                opts.prompt = vim.fn.fnamemodify(opts.cwd, ":~")
                local shorten_len = tonumber(opts.cwd_prompt_shorten_len)
                if shorten_len and #opts.prompt >= shorten_len then
                  opts.prompt = path.shorten(
                    opts.prompt,
                    tonumber(opts.cwd_prompt_shorten_val) or 1
                  )
                end
                if not path.ends_with_separator(opts.prompt) then
                  opts.prompt = opts.prompt .. path.separator()
                end
              end
              if opts.headers then
                opts = core.set_header(opts)
              end

              -- Get old picker from `opts.__resume_key`, fallback to files picker
              (fzf[opts.__resume_key] or fzf.files)(opts)
            end,
            ["esc"] = function()
              fzf.config.__resume_data = resume_data
              actions.resume()
            end,
            -- Should not change dir or exclude dirs when selecting cwd
            ["alt-c"] = false,
            ["alt-/"] = false,
          },
        }
      end

      ---Include directories, not only files when using the `files` picker
      ---@return nil
      function actions.toggle_dir(_, opts)
        local flag ---@type string?
        local flag_cmd_idx ---@type integer?
        local cmds = vim.iter(opts.cmd:gmatch "([^|;&]+[|;&]*)"):totable()

        -- Handle multiple cmds in one string, e.g. fzf-lua-frecency uses two
        -- commands in a row: 'cat ... ; fd ...'
        --
        -- fzf-lua-frecency does not support overriding cmd passed in `opts` yet
        -- TODO: make a PR for it
        for i, cmd in ipairs(cmds) do
          local exec = cmd:match "^%s*(%S+)"
          if exec == "fd" or exec == "fdfind" then
            flag = "--type d"
            flag_cmd_idx = i
            break
          end
          if exec == "find" then
            flag = "-type d"
            flag_cmd_idx = i
            break
          end
        end
        if not flag or not flag_cmd_idx then
          return
        end

        cmds[flag_cmd_idx] =
          fzf_utils.toggle_cmd_flag(cmds[flag_cmd_idx], flag)

        opts.__call_fn(vim.tbl_deep_extend("force", opts.__call_opts, {
          cmd = table.concat(cmds),
          resume = true,
        }))
      end

      ---Delete selected autocmd
      ---@return nil
      function actions.del_autocmd(selected)
        for _, line in ipairs(selected) do
          local event, group, pattern =
            line:match "^.+:%d+:|(%w+)%s*│%s*(%S+)%s*│%s*(.-)%s*│"
          if event and group and pattern then
            vim.cmd.autocmd {
              bang = true,
              args = { group, event, pattern },
              mods = { emsg_silent = true },
            }
          end
        end
        local query = fzf.config.__resume_data.last_query
        fzf.autocmds {
          fzf_opts = {
            ["--query"] = query ~= "" and query or nil,
          },
        }
      end

      ---Search & select files then add them to arglist
      ---@return nil
      function actions.arg_search_add()
        local opts = {
          query = fzf.config.__resume_data.last_query,
          cwd = fzf.config.__resume_data.opts.cwd,
        }

        fzf.files {
          cwd_header = true,
          cwd_prompt = false,
          prompt = "Argadd> ",
          actions = {
            ["enter"] = function(selected, o)
              -- Ported from https://github.com/ibhagwan/fzf-lua/blob/cae96b04f6cad98a3ad24349731df5e56b384c3c/lua/fzf-lua/actions.lua#L478-L491
              for _, sel in ipairs(selected) do
                local entry = path.entry_to_file(sel, o)
                local relpath = entry.bufname or entry.path
                assert(relpath, "entry doesn't contain filepath")
                if not relpath then
                  goto continue
                end
                if path.is_absolute(relpath) then
                  relpath = path.relative_to(relpath, fzf_utils.cwd())
                end
                vim.cmd.argadd(vim.fn.fnameescape(relpath))
                ::continue::
              end
              fzf.args(opts)
            end,
            ["esc"] = function()
              fzf.args(opts)
            end,
          },
          find_opts = [[-type f -not -path '*/\.git/*' -not -path '*/\.venv/*' -printf '%P\n']],
          fd_opts = [[--color=never --type f --type l --hidden --follow --exclude .git]],
          rg_opts = [[--color=never --files --hidden --follow -g '!.git']],
        }
      end

      local _file_split = actions.file_split
      local _file_vsplit = actions.file_vsplit
      local _file_tabedit = actions.file_tabedit
      local _file_sel_to_qf = actions.file_sel_to_qf
      local _file_sel_to_ll = actions.file_sel_to_ll
      local _buf_split = actions.buf_split
      local _buf_vsplit = actions.buf_vsplit
      local _buf_tabedit = actions.buf_tabedit

      ---@diagnostic disable-next-line: duplicate-set-field
      function actions.file_split(...)
        local win = vim.api.nvim_get_current_win()
        _file_split(...)
        if vim.api.nvim_win_is_valid(win) and utils.win.is_empty(win) then
          vim.api.nvim_win_close(win, false)
        end
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      function actions.file_vsplit(...)
        local win = vim.api.nvim_get_current_win()
        _file_vsplit(...)
        if vim.api.nvim_win_is_valid(win) and utils.win.is_empty(win) then
          vim.api.nvim_win_close(win, false)
        end
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      function actions.file_tabedit(...)
        local tab = vim.api.nvim_get_current_tabpage()
        _file_tabedit(...)
        if vim.api.nvim_tabpage_is_valid(tab) and utils.tab.is_empty(tab) then
          vim.api.nvim_win_close(vim.api.nvim_tabpage_list_wins(tab)[1], false)
        end
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      function actions.file_edit_or_qf(selected, opts)
        if #selected > 1 then
          actions.file_sel_to_qf(selected, opts)
          vim.cmd.cfirst()
          vim.cmd.copen()
        else
          -- Fix oil buffer concealing issue when opening some dirs
          vim.schedule(function()
            actions.file_edit(selected, opts)
          end)
        end
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      function actions.file_sel_to_qf(selected, opts)
        _file_sel_to_qf(selected, opts)
        if #selected > 1 then
          vim.cmd.cfirst()
          vim.cmd.copen()
        end
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      function actions.file_sel_to_ll(selected, opts)
        _file_sel_to_ll(selected, opts)
        if #selected > 1 then
          vim.cmd.lfirst()
          vim.cmd.lopen()
        end
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      function actions.buf_split(...)
        local win = vim.api.nvim_get_current_win()
        _buf_split(...)
        if vim.api.nvim_win_is_valid(win) and utils.win.is_empty(win) then
          vim.api.nvim_win_close(win, false)
        end
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      function actions.buf_vsplit(...)
        local win = vim.api.nvim_get_current_win()
        _buf_vsplit(...)
        if vim.api.nvim_win_is_valid(win) and utils.win.is_empty(win) then
          vim.api.nvim_win_close(win, false)
        end
      end

      ---@diagnostic disable-next-line: duplicate-set-field
      function actions.buf_tabedit(...)
        local tab = vim.api.nvim_get_current_tabpage()
        _buf_tabedit(...)
        if vim.api.nvim_tabpage_is_valid(tab) and utils.tab.is_empty(tab) then
          vim.api.nvim_win_close(vim.api.nvim_tabpage_list_wins(tab)[1], false)
        end
      end

      function actions.insert_register(...)
        actions.paste_register(...)
        vim.api.nvim_feedkeys("a", "n", true)
      end

      ---Check if fugitive `:Gedit` command exists
      ---@param notify? boolean whether to notify user when command does not exist
      ---@return boolean
      local function has_fugitive_gedit_cmd(notify)
        if vim.fn.exists ":Gedit" == 2 then
          return true
        end
        if notify then
          vim.notify(
            "[Fzf-lua] command `:Gedit` does not exist",
            vim.log.levels.WARN
          )
        end
        return false
      end

      ---Edit a git commit object with vim-fugitive
      function actions.fugitive_edit(selected)
        if not has_fugitive_gedit_cmd(true) or not selected[1] then
          return
        end
        vim.cmd.Gedit(selected[1]:match "^%x+")
      end

      ---Edit a git commit object in horizontal split with vim-fugitive
      function actions.fugitive_split(selected)
        if not has_fugitive_gedit_cmd(true) then
          return
        end
        vim.cmd.split()
        actions.fugitive_edit(selected, {})
      end

      ---Edit a git commit object in vertical split with vim-fugitive
      function actions.fugitive_vsplit(selected)
        if not has_fugitive_gedit_cmd(true) then
          return
        end
        vim.cmd.vsplit()
        actions.fugitive_edit(selected, {})
      end

      ---Edit a git commit object in vertical split with vim-fugitive
      function actions.fugitive_tabedit(selected)
        if not has_fugitive_gedit_cmd(true) then
          return
        end
        vim.cmd.tabnew()
        actions.fugitive_edit(selected, {})
      end

      core.ACTION_DEFINITIONS[actions.toggle_dir] = {
        function(o)
          -- When using `fd` the flag is '--type d', but for `find` the flag is
          -- '-type d', use '-type d' as default flag here anyway since it is
          -- the common substring for both `find` and `fd` commands
          local flag = o.toggle_dir_flag or "-type d"
          local escape = require("fzf-lua.utils").lua_regex_escape
          return o.cmd and o.cmd:match(escape(flag)) and "Exclude dirs"
            or "Include dirs"
        end,
      }
      core.ACTION_DEFINITIONS[actions.change_cwd] = { "Change cwd", pos = 1 }
      core.ACTION_DEFINITIONS[actions.arg_del] = { "delete" }
      core.ACTION_DEFINITIONS[actions.del_autocmd] = { "delete autocmd" }
      core.ACTION_DEFINITIONS[actions.arg_search_add] = { "add new file" }
      core.ACTION_DEFINITIONS[actions.search] = { "edit" }
      core.ACTION_DEFINITIONS[actions.ex_run] = { "edit" }
      core.ACTION_DEFINITIONS[actions.insert_register] = { "insert register" }
      core.ACTION_DEFINITIONS[actions.toggle_files_grep] =
        { "toggle files/grep" }
      core.ACTION_DEFINITIONS[actions.filter_extension] =
        { "extension filter" }

      config._action_to_helpstr[actions.toggle_dir] = "toggle-dir"
      config._action_to_helpstr[actions.switch_provider] = "switch-provider"
      config._action_to_helpstr[actions.change_cwd] = "change-cwd"
      config._action_to_helpstr[actions.arg_del] = "delete"
      config._action_to_helpstr[actions.del_autocmd] = "delete-autocmd"
      config._action_to_helpstr[actions.arg_search_add] =
        "search-and-add-new-file"
      config._action_to_helpstr[actions.file_split] = "file-split"
      config._action_to_helpstr[actions.file_vsplit] = "file-vsplit"
      config._action_to_helpstr[actions.file_tabedit] = "file-tabedit"
      config._action_to_helpstr[actions.file_edit_or_qf] = "file-edit-or-qf"
      config._action_to_helpstr[actions.file_sel_to_qf] =
        "file-select-to-quickfix"
      config._action_to_helpstr[actions.file_sel_to_ll] =
        "file-select-to-loclist"
      config._action_to_helpstr[actions.buf_split] = "buffer-split"
      config._action_to_helpstr[actions.buf_vsplit] = "buffer-vsplit"
      config._action_to_helpstr[actions.buf_tabedit] = "buffer-tabedit"
      config._action_to_helpstr[actions.buf_edit_or_qf] = "buffer-edit-or-qf"
      config._action_to_helpstr[actions.buf_sel_to_qf] =
        "buffer-select-to-quickfix"
      config._action_to_helpstr[actions.buf_sel_to_ll] =
        "buffer-select-to-loclist"
      config._action_to_helpstr[actions.insert_register] = "insert-register"
      config._action_to_helpstr[actions.fugitive_edit] = "fugitive-edit"
      config._action_to_helpstr[actions.fugitive_split] = "fugitive-split"
      config._action_to_helpstr[actions.fugitive_vsplit] = "fugitive-vsplit"
      config._action_to_helpstr[actions.fugitive_tabedit] = "fugitive-tabedit"
      config._action_to_helpstr[actions.toggle_files_grep] =
        "toggle-files-grep"
      config._action_to_helpstr[actions.filter_extension] = "extension-filter"

      -- Use different prompts for document and workspace diagnostics
      -- by overriding `fzf.diagnostics_workspace()` and `fzf.diagnostics_document()`
      -- because fzf-lua does not support setting different prompts for them via
      -- the `fzf.setup()` function, see `defaults.lua` & `providers/diagnostic.lua`
      local _diagnostics_workspace = fzf.diagnostics_workspace
      local _diagnostics_document = fzf.diagnostics_document

      ---@param opts table?
      function fzf.diagnostics_document(opts)
        return _diagnostics_document(vim.tbl_extend("force", opts or {}, {
          prompt = "Document Diagnostics> ",
        }))
      end

      ---@param opts table?
      function fzf.diagnostics_workspace(opts)
        return _diagnostics_workspace(vim.tbl_extend("force", opts or {}, {
          prompt = "Workspace Diagnostics> ",
        }))
      end

      ---Wrap fzf git pickers with dotfiles fallback when not inside git repo
      ---@param cb fun(opts: fzf-lua.config.GitBase?)
      ---@return fun(opts: fzf-lua.config.GitBase?)
      local function with_dotfiles_fallback(cb)
        return function(opts)
          local git_worktree, git_dir = utils.git.resolve_context(
            0,
            { { "--git-dir", vim.env.DOT_DIR, "--work-tree", vim.env.HOME } }
          )
          opts = vim.tbl_deep_extend("keep", opts or {}, {
            git_worktree = git_worktree,
            git_dir = git_dir,
          })
          return cb(opts)
        end
      end

      -- Fallback to dotfiles bare repo if not inside a normal git repository
      fzf.git_tags = with_dotfiles_fallback(fzf.git_tags)
      fzf.git_stash = with_dotfiles_fallback(fzf.git_stash)
      fzf.git_status = with_dotfiles_fallback(fzf.git_status)
      fzf.git_commits = with_dotfiles_fallback(fzf.git_commits)
      fzf.git_bcommits = with_dotfiles_fallback(fzf.git_bcommits)
      fzf.git_branches = with_dotfiles_fallback(fzf.git_branches)
      fzf.git_blame = with_dotfiles_fallback(fzf.git_blame)
      fzf.git_tags = with_dotfiles_fallback(fzf.git_tags)
      fzf.git_stash = with_dotfiles_fallback(fzf.git_stash)
      fzf.git_status = with_dotfiles_fallback(fzf.git_status)
      fzf.git_commits = with_dotfiles_fallback(fzf.git_commits)
      fzf.git_bcommits = with_dotfiles_fallback(fzf.git_bcommits)
      fzf.git_branches = with_dotfiles_fallback(fzf.git_branches)
      fzf.git_blame = with_dotfiles_fallback(fzf.git_blame)
      fzf.git_files = with_dotfiles_fallback(fzf.git_files)

      ---Search symbols, fallback to treesitter nodes if no language server
      ---supporting symbol method is attached
      ---@diagnostic disable-next-line: inject-field
      function fzf.symbols(opts)
        if
          vim.tbl_isempty(vim.lsp.get_clients {
            bufnr = 0,
            method = "textDocument/documentSymbol",
          })
        then
          return fzf.treesitter(opts)
        end
        return fzf.lsp_document_symbols(opts)
      end

      -- Override `vim.lsp.buf.document_symbol()` to use `fzf.symbols()`
      -- which fallback to treesitter nodes if no symbols are provided
      -- by attached language servers
      vim.lsp.buf.document_symbol = fzf.symbols

      -- Overriding `vim.lsp.buf.workspace_symbol()`, not only the handler here
      -- to skip the 'Query:' input prompt -- with `fzf.lsp_live_workspace_symbols()`
      -- as handler we can update the query in live
      local _lsp_workspace_symbol = vim.lsp.buf.workspace_symbol

      ---@diagnostic disable-next-line: duplicate-set-field
      function vim.lsp.buf.workspace_symbol(query, options)
        _lsp_workspace_symbol(query or "", options)
      end

      vim.lsp.buf.incoming_calls = fzf.lsp_incoming_calls
      vim.lsp.buf.outgoing_calls = fzf.lsp_outgoing_calls
      vim.lsp.buf.declaration = fzf.lsp_declarations
      vim.lsp.buf.definition = fzf.lsp_definitions
      vim.lsp.buf.document_symbol = fzf.lsp_document_symbols
      vim.lsp.buf.implementation = fzf.lsp_implementations
      vim.lsp.buf.references = fzf.lsp_references
      vim.lsp.buf.type_definition = fzf.lsp_typedefs
      vim.lsp.buf.workspace_symbol = fzf.lsp_live_workspace_symbols

      vim.diagnostic.setqflist = fzf.diagnostics_workspace
      vim.diagnostic.setloclist = fzf.diagnostics_document

      -- Fix fzf-lua's bug of not using source window's current cwd
      -- when used in conjunction with auto-cwd autocmd
      -- TODO: report to upstream
      local _fzf_files = fzf.files

      ---@param opts table?
      function fzf.files(opts)
        opts = opts or {}
        opts.cwd = opts.cwd or vim.fn.getcwd(0)
        return _fzf_files(opts)
      end

      -- Select dirs from `z`
      ---@param opts table?
      ---@diagnostic disable-next-line: inject-field
      function fzf.z(opts)
        local has_z_plugin, z = pcall(require, "plugin.z")
        if not has_z_plugin then
          vim.notify "[Fzf-lua] z plugin not found"
          return
        end

        -- Register action descriptions
        actions.z = z.jump
        core.ACTION_DEFINITIONS[actions.z] = { "jump to dir" }
        config._action_to_helpstr[actions.z] = "jump-to-dir"

        return fzf.fzf_exec(
          z.list(),
          vim.tbl_deep_extend("force", opts or {}, {
            cwd = vim.fn.getcwd(0),
            prompt = "Open directory: ",
            actions = {
              ["enter"] = actions.z,
            },
            fzf_opts = {
              ["--no-multi"] = true,
            },
          })
        )
      end

      -- Select/remove sessions from the session plugin
      ---@param opts table?
      ---@diagnostic disable-next-line: inject-field
      function fzf.sessions(opts)
        local has_session_plugin, session = pcall(require, "plugin.session")
        if not has_session_plugin then
          vim.notify "[Fzf-lua] session plugin not found"
          return
        end

        if vim.fn.executable "ls" == 0 then
          vim.notify "[Fzf-lua] `ls` command not available"
          return
        end

        ---Get keymap action
        ---@param cb fun(path?: string) session operation function (load, remove, etc.)
        ---@return fun(selected: string[])
        local function action(cb)
          return function(selected)
            vim.iter(selected):each(function(dir)
              cb(vim.fs.joinpath(session.opts.dir, session.dir2session(dir)))
            end)
          end
        end

        -- Register action descriptions
        actions.load_session = action(function(p)
          session.load(p, true)
        end)
        core.ACTION_DEFINITIONS[actions.load_session] = { "load session" }
        config._action_to_helpstr[actions.load_session] = "load-session"

        actions.remove_session = action(session.remove)
        core.ACTION_DEFINITIONS[actions.remove_session] = { "remove session" }
        config._action_to_helpstr[actions.remove_session] = "remove-session"

        return fzf.fzf_exec(
          string.format(
            [[ls -1 %s | while read -r file; do echo "$file" | sed 's/%%/\//g' | sed 's/\/\//%%/g'; done]],
            session.opts.dir
          ),
          vim.tbl_deep_extend("force", opts or {}, {
            prompt = "Sessions: ",
            actions = {
              ["enter"] = actions.load_session,
              ["ctrl-x"] = {
                fn = actions.remove_session,
                reload = true,
              },
            },
          })
        )
      end

      ---Fuzzy complete cmdline command/search history
      ---@param opts table?
      ---@diagnostic disable-next-line: inject-field
      function fzf.complete_cmdline(opts)
        opts = opts or {}
        opts.query = vim.fn.getcmdline()
        vim.api.nvim_feedkeys(vim.keycode "<C-\\><C-n>", "n", true)

        local type = vim.fn.getcmdtype()
        if type == ":" then
          fzf.command_history(opts)
          return
        end
        if type == "/" or type == "?" then
          opts.reverse_search = type == "?"
          fzf.search_history(opts)
          return
        end
      end

      ---Fuzzy complete from registers in insert mode
      ---@param opts table?
      ---@diagnostic disable-next-line: inject-field
      function fzf.complete_from_registers(opts)
        fzf.registers(vim.tbl_deep_extend("force", opts or {}, {
          actions = {
            ["enter"] = actions.insert_register,
          },
        }))
      end

      _G._fzf_lua_win_views = {}
      _G._fzf_lua_win_heights = {}

      ---@param name string
      ---@return nil
      local function restore_global_opt(name)
        local backup_name = "_fzf_" .. name
        local backup = vim.g[backup_name]
        if backup ~= nil and vim.go[name] ~= backup then
          vim.go[name] = backup
          vim.g[backup_name] = nil
        end
      end

      ---Restore window heights and views, supposed to be called after fzf opens or
      ---closes
      local function restore_win_heights_and_views()
        if vim.go.lines == vim.g._fzf_vim_lines then
          utils.win.restore_heights(_G._fzf_lua_win_heights)
        end
        utils.win.restore_views(_G._fzf_lua_win_views)
      end

      local use_bottom_float_preview = vim.g.fzf_lua_use_bottom_split ~= true

      function _G.FzfLuaFocus()
        local winid = vim.g._fzf_win
        if type(winid) ~= "number" or not vim.api.nvim_win_is_valid(winid) then
          local ok, loaded_fzf_utils = pcall(require, "fzf-lua.utils")
          local winobj = ok and loaded_fzf_utils.fzf_winobj() or nil
          winid = winobj and winobj.fzf_winid or nil
        end

        if type(winid) ~= "number" or not vim.api.nvim_win_is_valid(winid) then
          return false
        end

        vim.api.nvim_set_current_win(winid)
        vim.cmd.startinsert()
        return true
      end

      function _G.FzfLuaPreviewClose()
        local ok, loaded_fzf_utils = pcall(require, "fzf-lua.utils")
        local winobj = ok and loaded_fzf_utils.fzf_winobj() or nil
        if not winobj then
          return false
        end

        if winobj._dotfiles_preview_max then
          return _G.FzfLuaTogglePreviewMax()
        end

        if
          winobj.preview_winid
          and vim.api.nvim_win_is_valid(winobj.preview_winid)
        then
          winobj:toggle_preview()
        end
        vim.schedule(_G.FzfLuaFocus)
        return true
      end

      local function set_preview_keymaps(winid)
        if type(winid) ~= "number" or not vim.api.nvim_win_is_valid(winid) then
          return
        end

        local bufnr = vim.api.nvim_win_get_buf(winid)
        for _, lhs in ipairs { "q", "<Esc>", "<M-q>", "<C-w>q", "<F5>" } do
          vim.keymap.set("n", lhs, _G.FzfLuaPreviewClose, {
            buffer = bufnr,
            nowait = true,
            desc = "Close fzf preview",
          })
        end
      end

      function _G.FzfLuaFocusPreview()
        local ok, loaded_fzf_utils = pcall(require, "fzf-lua.utils")
        local winobj = ok and loaded_fzf_utils.fzf_winobj() or nil
        if
          not winobj
          or not winobj.has_previewer
          or not winobj:has_previewer()
        then
          return false
        end

        if winobj.preview_hidden then
          winobj:toggle_preview()
        end
        if
          winobj.preview_winid
          and vim.api.nvim_win_is_valid(winobj.preview_winid)
        then
          vim.api.nvim_set_current_win(winobj.preview_winid)
          set_preview_keymaps(winobj.preview_winid)
          return true
        end
        return false
      end

      function _G.FzfLuaTogglePreviewMax()
        local ok, loaded_fzf_utils = pcall(require, "fzf-lua.utils")
        local winobj = ok and loaded_fzf_utils.fzf_winobj() or nil
        if
          not winobj
          or not winobj.has_previewer
          or not winobj:has_previewer()
        then
          return false
        end

        if winobj._dotfiles_preview_max then
          local state = winobj._dotfiles_preview_max
          winobj._dotfiles_preview_max = nil
          winobj.fullscreen = state.fullscreen
          winobj.preview_hidden = state.preview_hidden
          winobj.toggle_behavior = state.toggle_behavior
          winobj._preview_pos_force = state.preview_pos_force
          winobj.winopts.preview.layout = state.layout
          winobj.winopts.preview.vertical = state.vertical
          winobj:redraw()
          vim.schedule(_G.FzfLuaFocus)
          return true
        end

        winobj._dotfiles_preview_max = {
          fullscreen = winobj.fullscreen,
          preview_hidden = winobj.preview_hidden,
          toggle_behavior = winobj.toggle_behavior,
          preview_pos_force = winobj._preview_pos_force,
          layout = winobj.winopts.preview.layout,
          vertical = winobj.winopts.preview.vertical,
        }

        winobj.fullscreen = true
        winobj.preview_hidden = false
        winobj.toggle_behavior = nil
        winobj._preview_pos_force = "up"
        winobj.winopts.preview.layout = "vertical"
        winobj.winopts.preview.vertical = "up:85%"
        winobj:redraw()
        vim.schedule(function()
          if
            winobj.preview_winid
            and vim.api.nvim_win_is_valid(winobj.preview_winid)
          then
            vim.api.nvim_set_current_win(winobj.preview_winid)
            set_preview_keymaps(winobj.preview_winid)
          end
        end)
        return true
      end

      local function fzf_split()
        vim.g._fzf_active = true
        local win = require "utils.win"
        win.save_heights "_fzf_lua_win_heights"
        win.save_views "_fzf_lua_win_views"

        vim.g._fzf_vim_lines = vim.o.lines
        vim.g._fzf_leave_win = vim.api.nvim_get_current_win()
        vim.g._fzf_splitkeep = vim.opt.splitkeep:get()
        vim.opt.splitkeep = "topline"
        vim.g._fzf_cmdheight = vim.opt.cmdheight:get()
        vim.opt.cmdheight = 0
        vim.g._fzf_laststatus = vim.opt.laststatus:get()
        vim.opt.laststatus = 0

        local fzf_height = 10

        local lastwin, lastwintype
        for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          local wintype = vim.fn.win_gettype(winid)
          if wintype ~= "autocmd" and wintype ~= "popup" then
            lastwin = winid
            lastwintype = wintype
            break
          end
        end

        if lastwintype == "loclist" or lastwintype == "quickfix" then
          vim.g._fzf_qfclosed = lastwintype
          vim.g._fzf_qfwin = lastwin
          vim.g._fzf_qfheight = vim.api.nvim_win_get_height(lastwin)
          fzf_height = vim.g._fzf_qfheight - 1
          vim.cmd(lastwintype == "loclist" and "lclose" or "cclose")
        end

        fzf_height = fzf_height
          + vim.g._fzf_cmdheight
          + (vim.g._fzf_laststatus > 0 and 1 or 0)

        if vim.g._fzf_n_items and not vim.g._fzf_qfclosed then
          fzf_height = math.min(fzf_height, vim.g._fzf_n_items + 1)
        end

        vim.cmd("botright " .. fzf_height .. "new")
        vim.g._fzf_win = vim.api.nvim_get_current_win()
        vim.w.winbar_no_attach = true
        vim.w.focus_disable = true
        vim.b.focus_disable = true
        vim.opt_local.buftype = "nofile"
        vim.opt_local.bufhidden = "wipe"
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.swapfile = false
        vim.opt_local.winfixwidth = true
        vim.opt_local.winfixheight = true
        vim.bo.filetype = "fzf"
      end

      fzf.setup {
        -- Default profile 'default-title' disables prompt in favor of title
        -- on nvim >= 0.9, but a fzf windows with split layout cannot have titles
        -- See https://github.com/ibhagwan/fzf-lua/issues/1739
        "default-prompt",
        -- Use nbsp in tty to avoid showing box chars
        ---@diagnostic disable-next-line: assign-type-mismatch
        nbsp = not vim.go.termguicolors and "\xc2\xa0" or nil,
        dir_icon = vim.trim(icons.Folder),
        winopts = {
          backdrop = 100,
          split = not use_bottom_float_preview and fzf_split or nil,
          height = use_bottom_float_preview and 23 or 0.85,
          width = 1,
          row = 1,
          col = 0,
          border = "none",
          on_create = function(args)
            vim.g._fzf_active = true
            vim.g._fzf_win = args and args.winid
              or vim.api.nvim_get_current_win()
            vim.keymap.set(
              "t",
              "<F5>",
              "<Cmd>lua _G.FzfLuaTogglePreviewMax()<CR>",
              {
                nowait = true,
                buffer = args and args.bufnr or true,
                desc = "Toggle large preview",
              }
            )
            vim.keymap.set(
              "t",
              "<F6>",
              "<Cmd>lua _G.FzfLuaFocusPreview()<CR>",
              {
                nowait = true,
                buffer = args and args.bufnr or true,
                desc = "Focus preview",
              }
            )
            vim.keymap.set(
              "t",
              "<C-r>",
              [['<C-\><C-N>"' . nr2char(getchar()) . 'pi']],
              {
                expr = true,
                buffer = true,
                desc = "Insert contents in a register",
              }
            )
            -- Sometimes windows will shift/change size after closing quickfix window
            -- and reopening fzf, maybe related to https://github.com/neovim/neovim/issues/30955
            if vim.g._fzf_qfclosed then
              restore_win_heights_and_views()
            end
          end,
          on_close = function()
            vim.defer_fn(function()
              vim.g._fzf_active = nil
              vim.g._fzf_win = nil
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                if vim.api.nvim_win_is_valid(win) then
                  vim.w[win].focus_disable = false
                  vim.b[vim.api.nvim_win_get_buf(win)].focus_disable = false
                end
              end
              pcall(function()
                require("focus").resize()
              end)
            end, 50)
            restore_global_opt "splitkeep"
            restore_global_opt "cmdheight"
            restore_global_opt "laststatus"

            restore_win_heights_and_views()

            -- Reopen quickfix/location list after closing fzf if we previous closed
            -- it to make space for fzf
            --
            -- Schedule in case the fzf is making a new split
            -- (e.g. `actions.file_split`) after opening quickfix window which
            -- resizes the quickfix window unexpectedly due to an nvim bug, see
            -- - `lua/core/autocmds.lua` augroup `fix_winfixheight_with_winbar`
            -- -  https://github.com/neovim/neovim/issues/30955
            vim.schedule(function()
              local win = vim.api.nvim_get_current_win()

              if vim.g._fzf_qfclosed then
                vim.cmd[vim.g._fzf_qfclosed == "loclist" and "lopen" or "copen"] {
                  count = vim.g._fzf_qfheight,
                }
                -- Restore window view & heights after re-opening quickfix windows
                -- to avoid evidentially resizing windows with `winfixheight` set, e.g.
                -- nvim-dap-ui windows
                -- See https://github.com/neovim/neovim/issues/30955
                restore_win_heights_and_views()
              end
              vim.g._fzf_qfclosed = nil
              vim.g._fzf_qfheight = nil

              -- Keep window visit order
              if
                vim.g._fzf_leave_win
                and vim.api.nvim_win_is_valid(vim.g._fzf_leave_win)
              then
                vim.api.nvim_set_current_win(vim.g._fzf_leave_win)
              end
              vim.g._fzf_leave_win = nil

              if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_set_current_win(win)
              end
            end)
          end,
          ---@diagnostic disable-next-line: missing-fields
          preview = use_bottom_float_preview
              and {
                border = "rounded",
                layout = "vertical",
                vertical = "up:12",
                hidden = true,
                delay = 80,
                scrollbar = false, ---@diagnostic disable-line: assign-type-mismatch
              }
            or {
              border = "none",
              layout = "horizontal",
              hidden = true,
              scrollbar = false, ---@diagnostic disable-line: assign-type-mismatch
            },
        },
        previewers = {
          builtin = {
            extensions = {
              avif = { "chafa", "--animate=off", "--scale=max", "{file}" },
              bmp = { "chafa", "--animate=off", "--scale=max", "{file}" },
              gif = { "chafa", "--animate=off", "--scale=max", "{file}" },
              jpeg = { "chafa", "--animate=off", "--scale=max", "{file}" },
              jpg = { "chafa", "--animate=off", "--scale=max", "{file}" },
              png = { "chafa", "--animate=off", "--scale=max", "{file}" },
              svg = { "chafa", "--animate=off", "--scale=max", "{file}" },
              webp = { "chafa", "--animate=off", "--scale=max", "{file}" },
            },
            syntax_delay = 80,
            toggle_behavior = "extend",
          },
        },
        -- Open help window at top of screen with single border
        help_open_win = function(buf, enter, opts)
          opts.border = "single"
          opts.row = 0
          opts.col = 0
          return vim.api.nvim_open_win(buf, enter, opts)
        end,
        fzf_colors = {
          ---@diagnostic disable-next-line: assign-type-mismatch
          ["fg+"] = { "fg", "CursorLine" },
          ["bg+"] = { "bg", "CursorLine" }, ---@diagnostic disable-line: assign-type-mismatch
          ["gutter"] = { "bg", "CursorLine" }, ---@diagnostic disable-line: assign-type-mismatch
        },
        keymap = {
          -- Overrides default completion completely
          builtin = {
            ["<C-_>"] = "toggle-help",
            ["<F1>"] = "toggle-help",
            ["<F2>"] = "toggle-fullscreen",
            ["<F3>"] = "toggle-preview-wrap",
            ["<F4>"] = "toggle-preview",
            ["<C-f>"] = "preview-page-down",
            ["<C-b>"] = "preview-page-up",
            ["<M-j>"] = "preview-down",
            ["<M-k>"] = "preview-up",
            ["<M-d>"] = "preview-half-page-down",
            ["<M-u>"] = "preview-half-page-up",
          },
          fzf = {
            -- fzf '--bind=' options
            ["ctrl-z"] = "abort",
            ["ctrl-k"] = "kill-line",
            ["ctrl-u"] = "unix-line-discard",
            ["ctrl-a"] = "beginning-of-line",
            ["ctrl-e"] = "end-of-line",
            ["alt-a"] = "toggle-all",
            ["alt-}"] = "last",
            ["alt-{"] = "first",
            ["tab"] = "toggle+down",
            ["shift-tab"] = "toggle+up",
            ["ctrl-l"] = "toggle",
            ["ctrl-n"] = "down",
            ["ctrl-p"] = "up",
          },
        },
        multiselect = true,
        actions = {
          files = {
            ["alt-s"] = actions.file_split,
            ["alt-v"] = actions.file_vsplit,
            ["alt-t"] = actions.file_tabedit,
            ["alt-q"] = actions.file_sel_to_qf,
            ["alt-l"] = actions.file_sel_to_ll,
            ["enter"] = actions.file_edit_or_qf,
          },
          buffers = {
            ["alt-s"] = actions.buf_split,
            ["alt-v"] = actions.buf_vsplit,
            ["alt-t"] = actions.buf_tabedit,
            ["ctrl-e"] = actions.filter_extension,
            ["ctrl-g"] = actions.toggle_files_grep,
            ["enter"] = actions.buf_edit_or_qf,
          },
        },
        defaults = {
          actions = {
            ---@diagnostic disable-next-line: assign-type-mismatch
            ["ctrl-]"] = actions.switch_provider,
          },
        },
        args = {
          files_only = false,
          actions = {
            ["ctrl-g"] = actions.toggle_files_grep,
            ["ctrl-s"] = actions.arg_search_add,
            ["ctrl-x"] = {
              fn = actions.arg_del,
              reload = true,
            },
          },
        },
        autocmds = {
          actions = {
            ["ctrl-x"] = {
              fn = actions.del_autocmd,
              -- reload = true,
            },
          },
        },
        blines = {
          actions = {
            ["alt-q"] = actions.buf_sel_to_qf,
            ["alt-l"] = actions.buf_sel_to_ll,
          },
        },
        lines = {
          actions = {
            ["alt-q"] = actions.buf_sel_to_qf,
            ["alt-l"] = actions.buf_sel_to_ll,
          },
        },
        buffers = {
          header = preview_hint,
          show_unlisted = false,
          show_unloaded = true,
          ignore_current_buffer = false,
          no_action_set_cursor = true,
          current_tab_only = false,
          no_term_buffers = false,
          cwd_only = false,
          ls_cmd = "ls",
          fzf_opts = {
            ["--header-first"] = true,
          },
        },
        helptags = {
          actions = {
            ["enter"] = actions.help,
            ["alt-s"] = actions.help,
            ["alt-v"] = actions.help_vert,
            ["alt-t"] = actions.help_tab,
          },
        },
        manpages = {
          actions = {
            ["enter"] = actions.man,
            ["alt-s"] = actions.man,
            ["alt-v"] = actions.man_vert,
            ["alt-t"] = actions.man_tab,
          },
        },
        keymaps = {
          actions = {
            ["enter"] = actions.keymap_edit,
            ["alt-s"] = actions.keymap_split,
            ["alt-v"] = actions.keymap_vsplit,
            ["alt-t"] = actions.keymap_tabedit,
          },
        },
        colorschemes = {
          actions = {
            ["enter"] = actions.colorscheme,
          },
        },
        command_history = {
          actions = {
            ["enter"] = actions.ex_run,
            ["ctrl-e"] = false,
          },
        },
        search_history = {
          actions = {
            ["enter"] = actions.search,
            ["ctrl-e"] = false,
          },
        },
        files = {
          header = preview_hint,
          actions = {
            ["alt-c"] = actions.change_cwd,
            ["alt-h"] = actions.toggle_hidden,
            ["alt-i"] = actions.toggle_ignore,
            ["alt-/"] = actions.toggle_dir,
            ["ctrl-e"] = actions.filter_extension,
            ["ctrl-g"] = actions.toggle_files_grep,
          },
          fzf_opts = {
            ["--header-first"] = true,
            ["--info"] = "inline-right",
          },
          find_opts = [[-type f -not -path '*/\.git/*' -not -path '*/\.venv/*' -printf '%P\n']],
          fd_opts = [[--color=never --type f --type l --hidden --follow --exclude .git --exclude .venv]],
          rg_opts = [[--no-messages --color=never --files --hidden --follow -g '!.git' -g '!.venv']],
        },
        oldfiles = {
          prompt = "Oldfiles> ",
          header = preview_hint,
          actions = {
            ["ctrl-e"] = actions.filter_extension,
            ["ctrl-g"] = actions.toggle_files_grep,
          },
          fzf_opts = {
            ["--header-first"] = true,
          },
        },
        frecency = {
          prompt = "Frecency> ",
          track_by_score = true,
        },
        git = {
          status = {
            winopts = {
              preview = {
                hidden = true,
              },
            },
          },
          commits = {
            prompt = "GitLogs>",
            winopts = {
              preview = {
                hidden = true,
              },
            },
            actions = has_fugitive_gedit_cmd() and {
              ["enter"] = actions.fugitive_edit,
              ["alt-s"] = actions.fugitive_split,
              ["alt-v"] = actions.fugitive_vsplit,
              ["alt-t"] = actions.fugitive_tabedit,
              ["ctrl-y"] = {
                fn = actions.git_yank_commit,
                exec_silent = true,
              },
            } or nil,
          },
          bcommits = {
            prompt = "GitBLogs>",
            winopts = {
              preview = {
                hidden = true,
              },
            },
            actions = has_fugitive_gedit_cmd() and {
              ["enter"] = actions.fugitive_edit,
              ["alt-s"] = actions.fugitive_split,
              ["alt-v"] = actions.fugitive_vsplit,
              ["alt-t"] = actions.fugitive_tabedit,
              ["ctrl-y"] = {
                fn = actions.git_yank_commit,
                exec_silent = true,
              },
            } or nil,
          },
          blame = {
            winopts = {
              preview = {
                hidden = true,
              },
            },
            actions = {
              ["enter"] = actions.git_goto_line,
              ["alt-s"] = actions.git_buf_split,
              ["alt-v"] = actions.git_buf_vsplit,
              ["alt-t"] = actions.git_buf_tabedit,
              ["ctrl-y"] = { fn = actions.git_yank_commit, exec_silent = true },
            },
          },
          branches = {
            actions = {
              ["ctrl-s"] = {
                fn = actions.git_branch_add,
                field_index = "{q}",
                reload = true,
              },
            },
          },
        },
        fzf_opts = {
          ["--no-scrollbar"] = "",
          ["--no-separator"] = "",
          ["--info"] = "inline-right",
          ["--layout"] = "reverse",
          ["--no-unicode"] = not vim.g.has_nf,
          ["--marker"] = not vim.g.has_nf and icons.GitSignAdd or nil,
          ["--pointer"] = not vim.g.has_nf and icons.AngleRight or nil,
          ["--border"] = "none",
          ["--padding"] = "0,1",
          ["--margin"] = "0",
        },
        grep = {
          -- Respect global ripgrep config, see
          -- - https://github.com/ibhagwan/fzf-lua/issues/2187
          -- - https://github.com/ibhagwan/fzf-lua/issues/1506#issuecomment-2447299360
          RIPGREP_CONFIG_PATH = vim.env.RIPGREP_CONFIG_PATH,
          query_delay = 100,
          rg_glob = true,
          silent_fail = true,
          actions = {
            ["alt-c"] = actions.change_cwd,
            ["alt-h"] = actions.toggle_hidden,
            ["alt-i"] = actions.toggle_ignore,
            ["ctrl-g"] = actions.toggle_files_grep,
          },
          rg_opts = table.concat({
            "--no-messages",
            "--hidden",
            "--follow",
            "--smart-case",
            "--column",
            "--line-number",
            "--no-heading",
            "--max-columns=4096",
            "--color=always",
            "-g=!.git/",
            "-e",
          }, " "),
          fzf_opts = {
            ["--header-first"] = true,
            ["--info"] = "inline-right",
          },
          header = preview_hint,
          winopts = {
            preview = {
              hidden = false,
            },
          },
        },
        lsp = {
          jump1 = true,
          finder = {
            winopts = {
              preview = {
                hidden = true,
              },
            },
            fzf_opts = {
              ["--info"] = "inline-right",
            },
          },
          references = {
            sync = false,
            ignore_current_line = true,
            winopts = {
              preview = {
                hidden = true,
              },
            },
          },
          definitions = {
            sync = false,
            winopts = {
              preview = {
                hidden = true,
              },
            },
          },
          typedefs = {
            sync = false,
            winopts = {
              preview = {
                hidden = true,
              },
            },
          },
          symbols = {
            symbol_style = vim.g.has_nf and 1 or 3,
            symbol_icons = vim.tbl_map(vim.trim, icons.kinds),
            symbol_hl = function(sym_name)
              return "FzfLuaSym" .. sym_name
            end,
          },
        },
        diagnostics = {
          multiline = false,
          winopts = {
            preview = {
              hidden = true,
            },
          },
        },
      }

      -- stylua: ignore start
      vim.keymap.set('c', '<C-_>', fzf.complete_cmdline, { desc = 'Fuzzy complete command/search history' })
      vim.keymap.set('c', '<C-x><C-l>', fzf.complete_cmdline, { desc = 'Fuzzy complete command/search history' })
      vim.keymap.set('i', '<C-r>?', fzf.complete_from_registers, { desc = 'Fuzzy complete from registers' })
      vim.keymap.set('i', '<C-r><C-_>', fzf.complete_from_registers, { desc = 'Fuzzy complete from registers' })
      vim.keymap.set('i', '<C-r><C-r>', fzf.complete_from_registers, { desc = 'Fuzzy complete from registers' })
      vim.keymap.set('i', '<C-x><C-f>', fzf.complete_path, { desc = 'Fuzzy complete path' })
      vim.keymap.set('n', '<Leader>.', function() fzf.smart_files() end, { desc = 'Smart files' })

      local function valid_dir(dir)
        return type(dir) == "string"
          and dir ~= ""
          and vim.fn.isdirectory(dir) == 1
          and vim.fs.normalize(dir)
      end

      local function smart_files_cwd(opts)
        local explicit_cwd = valid_dir(opts.cwd)
        if explicit_cwd then
          return explicit_cwd
        end

        local fs_utils = require "utils.fs"
        local window_cwd = valid_dir(vim.fn.getcwd(0))
        if
          window_cwd
          and not fs_utils.is_home_dir(window_cwd)
          and not fs_utils.is_root_dir(window_cwd)
        then
          return window_cwd
        end

        local bufname = vim.api.nvim_buf_get_name(0)
        local buffer_root = bufname ~= "" and fs_utils.cwd_dir(bufname) or nil
        if
          buffer_root
          and not fs_utils.is_home_dir(buffer_root)
          and not fs_utils.is_root_dir(buffer_root)
        then
          return buffer_root
        end

        if window_cwd then
          return window_cwd
        end

        local last_cwd = valid_dir(vim.g._smart_files_last_cwd)
        if last_cwd then
          return last_cwd
        end

        return valid_dir(vim.fn.getcwd()) or valid_dir(vim.uv.cwd()) or "."
      end

      ---Smart file search that prioritizes recent files in cwd
      ---@param opts table?
      function fzf.smart_files(opts)
        opts = opts or {}
        local cwd = smart_files_cwd(opts)
        local real_cwd = vim.uv.fs_realpath(cwd) or cwd
        local oldfiles = vim.v.oldfiles or {}
        local other_oldfiles_limit = opts.smart_other_oldfiles_limit or 5
        local oldfiles_scan_limit = opts.smart_oldfiles_scan_limit or 1000

        -- Filter oldfiles to current cwd
        local cwd_oldfiles = {}
        local other_oldfiles = {}
        local cwd_seen = {}
        local other_seen = {}

        for i, f in ipairs(oldfiles) do
          if i > oldfiles_scan_limit then
            break
          end
          if type(f) == 'string' and f ~= '' then
            -- Check if file exists
            local real_file = vim.uv.fs_realpath(f)
            local exists = real_file ~= nil
            if not exists then
              goto skip
            end

            -- Convert absolute path to ~ if in home
            local display_path = f
            if vim.startswith(f, vim.env.HOME .. '/') then
              display_path = '~' .. f:gsub('^' .. vim.env.HOME, '')
            end

            -- Check if file is in cwd
            if vim.startswith(real_file, real_cwd .. '/') then
              local rel_path = real_file:gsub('^' .. vim.pesc(real_cwd) .. '/?', '')
              if not cwd_seen[rel_path] and rel_path ~= '' then
                cwd_seen[rel_path] = true
                table.insert(cwd_oldfiles, rel_path)
              end
            else
              if
                not other_seen[display_path]
                and #other_oldfiles < other_oldfiles_limit
              then
                other_seen[display_path] = true
                table.insert(other_oldfiles, display_path)
              end
            end
            ::skip::
          end
        end

        local excludes = opts.smart_excludes
          or { ".git", ".venv", "node_modules", "dist", ".next" }

        -- Get file command
        local file_cmd
        if vim.fn.executable('fd') == 1 then
          file_cmd = { 'fd', '--type', 'f', '--hidden', '--follow' }
        elseif vim.fn.executable('fdfind') == 1 then
          file_cmd = { 'fdfind', '--type', 'f', '--hidden', '--follow' }
        else
          file_cmd = { 'find', '.', '-type', 'f' }
        end

        for _, exclude in ipairs(excludes) do
          if file_cmd[1] == 'fd' or file_cmd[1] == 'fdfind' then
            vim.list_extend(file_cmd, { '--exclude', exclude })
          else
            vim.list_extend(file_cmd, { '-not', '-path', '*/' .. exclude .. '/*' })
          end
        end

        -- Build combined command - cwd recent files first, then others, then all files
        local parts = {}
        if #cwd_oldfiles > 0 then
          table.insert(parts, "printf '%s\\n' " .. table.concat(vim.tbl_map(shellescape, cwd_oldfiles), " "))
        end
        if #other_oldfiles > 0 then
          table.insert(parts, "printf '%s\\n' " .. table.concat(vim.tbl_map(shellescape, other_oldfiles), " "))
        end
        table.insert(parts, table.concat(file_cmd, ' ') .. " | sed 's|^\\./||'")

        -- Combine and deduplicate using awk
        local cmd = "{ " .. table.concat(parts, "; ") .. "; } | awk '!a[$0]++'"

        -- Use fzf.files with custom command and file icons
        local smart_actions = {
          ['ctrl-e'] = actions.filter_extension,
          ['ctrl-g'] = actions.toggle_files_grep,
          ['enter'] = function(selected, o)
            if selected[1] then
              local entry = path.entry_to_file(selected[1], o, false)
              local selected_path = entry.path or entry.bufname or selected[1]
              local abs_path = path.is_absolute(selected_path) and selected_path
                or vim.fs.normalize(o.cwd .. "/" .. selected_path)
              local new_cwd = require("utils.fs").cwd_dir(abs_path)
                or vim.fs.dirname(abs_path)
              if new_cwd then
                local valid_cwd = valid_dir(new_cwd)
                if valid_cwd then
                  vim.g._smart_files_last_cwd = valid_cwd
                end
              end
            end
            actions.file_edit(selected, o)
          end,
        }

        return fzf.files(vim.tbl_deep_extend('force', {
          prompt = 'Smart Files> ',
          cwd = cwd,
          cmd = cmd,
          __smart_files = true,
          formatter = "path.filename_first",
          header = preview_header "Smart Files: recent cwd files first",
          fzf_opts = {
            ["--header-first"] = true,
          },
          actions = smart_actions,
        }, opts))
      end

      ---Browse image files with preview visible by default.
      ---@param opts table?
      function fzf.images(opts)
        opts = opts or {}
        local cwd = smart_files_cwd(opts)
        local image_exts =
          { "avif", "bmp", "gif", "jpeg", "jpg", "png", "svg", "webp" }
        local file_cmd
        if vim.fn.executable('fd') == 1 or vim.fn.executable('fdfind') == 1 then
          local fd = vim.fn.executable('fd') == 1 and 'fd' or 'fdfind'
          file_cmd = { fd, '--type', 'f', '--hidden', '--follow' }
          for _, ext in ipairs(image_exts) do
            vim.list_extend(file_cmd, { '--extension', ext })
          end
          vim.list_extend(file_cmd, {
            '--exclude',
            '.git',
            '--exclude',
            'node_modules',
          })
        else
          file_cmd = {
            'find',
            '.',
            '-type',
            'f',
            '(',
            '-iname',
            '*.avif',
          }
          for _, ext in ipairs({ "bmp", "gif", "jpeg", "jpg", "png", "svg", "webp" }) do
            vim.list_extend(file_cmd, { '-o', '-iname', '*.' .. ext })
          end
          table.insert(file_cmd, ')')
        end

        return fzf.files(vim.tbl_deep_extend('force', {
          prompt = 'Images> ',
          cwd = cwd,
          cmd = table.concat(vim.tbl_map(shellescape, file_cmd), ' '),
          formatter = "path.filename_first",
          header = preview_header "Images",
          jump1 = false,
          fzf_opts = {
            ["--header-first"] = true,
          },
          winopts = {
            preview = {
              hidden = false,
            },
          },
        }, opts))
      end

      ---Project picker with compact home-relative paths.
      ---@param opts table?
      function fzf.projects(opts)
        opts = opts or {}
        local ok, project = pcall(require, "project")
        if not ok then
          pcall(vim.cmd.packadd, "project.nvim")
          ok, project = pcall(require, "project")
        end
        if not ok then
          vim.notify("[Fzf-lua] project.nvim not found", vim.log.levels.WARN)
          return
        end

        local projects = reverse_list(project.get_recent_projects() or {})
        if #projects == 0 then
          vim.notify("[Fzf-lua] no recent projects", vim.log.levels.INFO)
          return
        end

        local entries = {}
        local project_by_display = {}
        local folder_icon = vim.g.has_nf and vim.trim(icons.Folder) or "dir"
        for _, project_path in ipairs(projects) do
          local display = ("%s  %s"):format(folder_icon, home_path(project_path))
          project_by_display[display] = project_path
          table.insert(entries, display .. "\t" .. project_path)
        end

        local function selected_projects(selected)
          local paths = {}
          for _, entry in ipairs(selected or {}) do
            local project_path = entry:match("\t(.+)$") or entry
            project_path = project_by_display[project_path] or project_path
            if project_path ~= "" then
              table.insert(paths, project_path)
            end
          end
          return paths
        end

        local function open_project(selected)
          local project_path = selected_projects(selected)[1]
          if not project_path then
            return
          end
          fzf.files({
            cwd = project_path,
            cwd_only = true,
            hidden = true,
          })
        end

        local function delete_project(selected)
          local ok_history, history = pcall(require, "project.util.history")
          if not ok_history then
            return
          end
          for _, project_path in ipairs(selected_projects(selected)) do
            history.delete_project(project_path, true)
          end
          actions.resume()
        end

        local function cd_project(selected)
          local project_path = selected_projects(selected)[1]
          if not project_path then
            return
          end
          local ok_api, project_api = pcall(require, "project.api")
          if ok_api then
            project_api.set_pwd(project_path, "fzf-lua")
          else
            vim.api.nvim_set_current_dir(project_path)
          end
          fzf.smart_files({ cwd = project_path })
        end

        return fzf.fzf_exec(entries, vim.tbl_deep_extend('force', {
          prompt = 'Projects> ',
          header = "enter: files | alt-c/ctrl-w: cd + files | ctrl-d: delete",
          fzf_opts = {
            ["--delimiter"] = "\t",
            ["--header-first"] = true,
            ["--with-nth"] = "1",
          },
          actions = {
            ["alt-c"] = cd_project,
            ["ctrl-d"] = delete_project,
            ["ctrl-w"] = cd_project,
            ["enter"] = open_project,
          },
        }, opts))
      end

      vim.keymap.set('n', '<Leader><space>', function() fzf.smart_files() end, { desc = 'Smart files (prioritize recent)' })
      vim.keymap.set('n', '<Leader>sp', function() fzf.projects() end, { desc = 'Find projects (fzf)' })
      vim.keymap.set('n', "<Leader>'", fzf.resume, { desc = 'Resume last picker' })
      vim.keymap.set('n', "<Leader>`", fzf.marks, { desc = 'Find marks' })
      vim.keymap.set('n', '<Leader>,', fzf.buffers, { desc = 'Find buffers' })
      vim.keymap.set('n', '<Leader>%', fzf.tabs, { desc = 'Find tabpages' })
      vim.keymap.set('n', '<Leader>/', fzf.live_grep, { desc = 'Grep' })
      vim.keymap.set('n', '<Leader>?', fzf.help_tags, { desc = 'Find help tags' })
      vim.keymap.set('n', '<Leader>*', fzf.grep_cword, { desc = 'Grep word under cursor' })
      vim.keymap.set('x', '<Leader>*', fzf.grep_visual, { desc = 'Grep visual selection' })
      vim.keymap.set('n', '<Leader>#', fzf.grep_cword, { desc = 'Grep word under cursor' })
      vim.keymap.set('x', '<Leader>#', fzf.grep_visual, { desc = 'Grep visual selection' })
      vim.keymap.set('n', '<Leader>"', fzf.registers, { desc = 'Find registers' })
      vim.keymap.set('n', '<Leader>:', fzf.commands, { desc = 'Find commands' })
      vim.keymap.set('n', '<Leader>F', fzf.builtin, { desc = 'Find all available pickers' })
      vim.keymap.set('n', '<Leader>p', fzf.oldfiles, { desc = 'Find old files' })
      -- vim.keymap.set('n', '<Leader>-', fzf.blines, { desc = 'Find lines in buffer' })
      vim.keymap.set('n', '<Leader>=', fzf.lines, { desc = 'Find lines across buffers' })
      -- vim.keymap.set('x', '<Leader>-', fzf.blines, { desc = 'Find lines in selection' })
      vim.keymap.set('x', '<Leader>=', fzf.blines, { desc = 'Find lines in selection' })
      vim.keymap.set('n', '<Leader>n', fzf.treesitter, { desc = 'Find treesitter nodes' })
      vim.keymap.set('n', '<Leader>R', fzf.lsp_finder, { desc = 'Find symbol locations' })
      vim.keymap.set('n', '<Leader>f"', fzf.registers, { desc = 'Find registers' })
      vim.keymap.set('n', '<Leader>f*', fzf.grep_cword, { desc = 'Grep word under cursor' })
      vim.keymap.set('x', '<Leader>f*', fzf.grep_visual, { desc = 'Grep visual selection' })
      vim.keymap.set('n', '<Leader>f#', fzf.grep_cword, { desc = 'Grep word under cursor' })
      vim.keymap.set('x', '<Leader>f#', fzf.grep_visual, { desc = 'Grep visual selection' })
      vim.keymap.set('n', '<Leader>f:', fzf.commands, { desc = 'Find commands' })
      vim.keymap.set('n', '<Leader>f/', fzf.live_grep, { desc = 'Grep' })
      vim.keymap.set('n', '<Leader>fH', fzf.highlights, { desc = 'Find highlights' })
      vim.keymap.set('n', '<Leader>fi', function() fzf.images() end, { desc = 'Find images' })
      vim.keymap.set('n', "<Leader>f'", fzf.resume, { desc = 'Resume last picker' })
      vim.keymap.set('n', '<Leader>fA', fzf.autocmds, { desc = 'Find autocommands' })
      vim.keymap.set('n', '<Leader>fb', fzf.buffers, { desc = 'Find buffers' })
      vim.keymap.set('n', '<Leader>bb', fzf.buffers, { desc = 'Find buffers' })
      vim.keymap.set('n', '<Leader>fp', fzf.tabs, { desc = 'Find tabpages' })
      vim.keymap.set('n', '<Leader>ft', fzf.tags, { desc = 'Find tags' })
      vim.keymap.set('n', '<Leader>fc', fzf.changes, { desc = 'Find changes' })
      vim.keymap.set('n', '<Leader>fd', fzf.diagnostics_document, { desc = 'Find document diagnostics' })
      vim.keymap.set('n', '<Leader>fD', fzf.diagnostics_workspace, { desc = 'Find workspace diagnostics' })
      vim.keymap.set('n', '<Leader>ff', function() fzf.smart_files() end, { desc = 'Smart files' })
      vim.keymap.set('n', '<Leader>fa', fzf.args, { desc = 'Find args' })
      vim.keymap.set('n', '<Leader>fl', fzf.loclist, { desc = 'Find location list' })
      vim.keymap.set('n', '<Leader>fq', fzf.quickfix, { desc = 'Find quickfix list' })
      vim.keymap.set('n', '<Leader>fL', fzf.loclist_stack, { desc = 'Find location list stack' })
      vim.keymap.set('n', '<Leader>fQ', fzf.quickfix_stack, { desc = 'Find quickfix stack' })
      vim.keymap.set('n', '<Leader>fgt', fzf.git_tags, { desc = 'Find git tags' })
      vim.keymap.set('n', '<Leader>fgs', fzf.git_stash, { desc = 'Find git stash' })
      vim.keymap.set('n', '<Leader>sx', fzf.git_status, { desc = 'Find git status' })
      vim.keymap.set('n', '<Leader>fgL', fzf.git_commits, { desc = 'Find git logs' })
      vim.keymap.set('n', '<Leader>fgl', fzf.git_bcommits, { desc = 'Find git buffer logs' })
      vim.keymap.set('n', '<Leader>fgb', fzf.git_branches, { desc = 'Find git branches' })
      vim.keymap.set('n', '<Leader>fgB', fzf.git_blame, { desc = 'Find git blame' })
      vim.keymap.set('n', '<Leader>fgf', fzf.git_files, { desc = 'Find git files' })
      vim.keymap.set('n', '<Leader>gft', fzf.git_tags, { desc = 'Find git tags' })
      vim.keymap.set('n', '<Leader>gfs', fzf.git_stash, { desc = 'Find git stash' })
      vim.keymap.set('n', '<Leader>gfg', fzf.git_status, { desc = 'Find git status' })
      vim.keymap.set('n', '<Leader>gfL', fzf.git_commits, { desc = 'Find git logs' })
      vim.keymap.set('n', '<Leader>gfl', fzf.git_bcommits, { desc = 'Find git buffer logs' })
      vim.keymap.set('n', '<Leader>gfb', fzf.git_branches, { desc = 'Find git branches' })
      vim.keymap.set('n', '<Leader>gfB', fzf.git_blame, { desc = 'Find git blame' })
      vim.keymap.set('n', '<Leader>gff', fzf.git_files, { desc = 'Find git files' })
      vim.keymap.set('n', '<Leader>fh', fzf.help_tags, { desc = 'Find help tags' })
      vim.keymap.set('n', '<Leader>fk', fzf.keymaps, { desc = 'Find keymaps' })
      vim.keymap.set('n', '<Leader>f-', fzf.blines, { desc = 'Find lines in buffer' })
      vim.keymap.set('x', '<Leader>f-', fzf.blines, { desc = 'Find lines in selection' })
      vim.keymap.set('n', '<Leader>f=', fzf.lines, { desc = 'Find lines across buffers' })
      vim.keymap.set('n', '<Leader>fm', fzf.marks, { desc = 'Find marks' })
      vim.keymap.set('n', '<Leader>fo', fzf.oldfiles, { desc = 'Find old files' })
      vim.keymap.set('n', '<Leader>fz', fzf.z, { desc = 'Find directories from z' })
      vim.keymap.set('n', '<Leader>fw', fzf.sessions, { desc = 'Find sessions (workspaces)' })
      vim.keymap.set('n', '<Leader>fn', fzf.treesitter, { desc = 'Find treesitter nodes' })
      vim.keymap.set('n', '<Leader>fs', fzf.symbols, { desc = 'Find lsp symbols or treesitter nodes' })
      vim.keymap.set('n', '<Leader>fSa', fzf.lsp_code_actions, { desc = 'Find code actions' })
      vim.keymap.set('n', '<Leader>fSd', fzf.lsp_definitions, { desc = 'Find symbol definitions' })
      vim.keymap.set('n', '<Leader>fSD', fzf.lsp_declarations, { desc = 'Find symbol declarations' })
      vim.keymap.set('n', '<Leader>fS<C-d>', fzf.lsp_typedefs, { desc = 'Find symbol type definitions' })
      vim.keymap.set('n', '<Leader>fSs', fzf.lsp_document_symbols, { desc = 'Find document symbols' })
      vim.keymap.set('n', '<Leader>fSS', fzf.lsp_live_workspace_symbols, { desc = 'Find workspace symbols' })
      vim.keymap.set('n', '<Leader>fSi', fzf.lsp_implementations, { desc = 'Find symbol implementations' })
      vim.keymap.set('n', '<Leader>fS<', fzf.lsp_incoming_calls, { desc = 'Find symbol incoming calls' })
      vim.keymap.set('n', '<Leader>fS>', fzf.lsp_outgoing_calls, { desc = 'Find symbol outgoing calls' })
      vim.keymap.set('n', '<Leader>fSr', fzf.lsp_references, { desc = 'Find symbol references' })
      vim.keymap.set('n', '<Leader>fSR', fzf.lsp_finder, { desc = 'Find symbol locations' })
      vim.keymap.set('n', '<Leader>fF', fzf.builtin, { desc = 'Find all available pickers' })
      vim.keymap.set('n', '<Leader>f<Esc>', '<Nop>', { desc = 'Cancel' })
      -- stylua: ignore end

      utils.hl.persist(function()
        -- stylua: ignore start
        utils.hl.set(0, 'FzfLuaSymDefault',       { link = 'Special',             default = true })
        utils.hl.set(0, 'FzfLuaSymArray',         { link = 'Operator',            default = true })
        utils.hl.set(0, 'FzfLuaSymBoolean',       { link = 'Boolean',             default = true })
        utils.hl.set(0, 'FzfLuaSymClass',         { link = 'Type',                default = true })
        utils.hl.set(0, 'FzfLuaSymConstant',      { link = 'Constant',            default = true })
        utils.hl.set(0, 'FzfLuaSymConstructor',   { link = '@constructor',        default = true })
        utils.hl.set(0, 'FzfLuaSymEnum',          { link = 'Constant',            default = true })
        utils.hl.set(0, 'FzfLuaSymEnumMember',    { link = 'FzfLuaSymEnum',       default = true })
        utils.hl.set(0, 'FzfLuaSymEvent',         { link = '@lsp.type.event',     default = true })
        utils.hl.set(0, 'FzfLuaSymField',         { link = 'FzfLuaSymDefault',    default = true })
        utils.hl.set(0, 'FzfLuaSymFile',          { link = 'Directory',           default = true })
        utils.hl.set(0, 'FzfLuaSymFunction',      { link = 'Function',            default = true })
        utils.hl.set(0, 'FzfLuaSymInterface',     { link = 'Type',                default = true })
        utils.hl.set(0, 'FzfLuaSymKey',           { link = '@keyword',            default = true })
        utils.hl.set(0, 'FzfLuaSymMethod',        { link = 'Function',            default = true })
        utils.hl.set(0, 'FzfLuaSymModule',        { link = '@module',             default = true })
        utils.hl.set(0, 'FzfLuaSymNamespace',     { link = '@lsp.type.namespace', default = true })
        utils.hl.set(0, 'FzfLuaSymNull',          { link = 'Constant',            default = true })
        utils.hl.set(0, 'FzfLuaSymNumber',        { link = 'Number',              default = true })
        utils.hl.set(0, 'FzfLuaSymObject',        { link = 'Statement',           default = true })
        utils.hl.set(0, 'FzfLuaSymOperator',      { link = 'Operator',            default = true })
        utils.hl.set(0, 'FzfLuaSymPackage',       { link = '@module',             default = true })
        utils.hl.set(0, 'FzfLuaSymProperty',      { link = 'FzfLuaSymDefault',    default = true })
        utils.hl.set(0, 'FzfLuaSymString',        { link = '@string',             default = true })
        utils.hl.set(0, 'FzfLuaSymStruct',        { link = 'Type',                default = true })
        utils.hl.set(0, 'FzfLuaSymTypeParameter', { link = 'FzfLuaSymDefault',    default = true })
        utils.hl.set(0, 'FzfLuaSymVariable',      { link = 'FzfLuaSymDefault',    default = true })
        utils.hl.set(0, 'FzfLuaNormal',           { link = 'NormalSpecial'       })
        utils.hl.set(0, 'FzfLuaBorder',           { link = 'FloatBorder'         })
        utils.hl.set(0, 'FzfLuaPreviewBorder',    { link = 'FloatBorder'         })
        utils.hl.set(0, 'FzfLuaPreviewTitle',     { link = 'FloatBorder'         })
        utils.hl.set(0, 'FzfLuaBufFlagAlt',       { link = 'FzfLuaSymDefault'    })
        utils.hl.set(0, 'FzfLuaBufFlagCur',       { link = 'Operator'            })
        utils.hl.set(0, 'FzfLuaLiveSym',          { link = 'WarningMsg'          })
        utils.hl.set(0, 'FzfLuaPathColNr',        { link = 'FzfLuaSymDefault'    })
        utils.hl.set(0, 'FzfLuaPathLineNr',       { link = 'FzfLuaSymDefault'    })
        utils.hl.set(0, 'FzfLuaBufLineNr',        { link = 'LineNr'              })
        utils.hl.set(0, 'FzfLuaCursor',           { link = 'None'                })
        utils.hl.set(0, 'FzfLuaHeaderBind',       { link = 'FzfLuaSymDefault'    })
        utils.hl.set(0, 'FzfLuaHeaderText',       { link = 'FzfLuaSymDefault'    })
        utils.hl.set(0, 'FzfLuaTabMarker',        { link = 'Keyword'             })
        utils.hl.set(0, 'FzfLuaTabTitle',         { link = 'Title'               })
        utils.hl.set(0, 'FzfLuaDirPart',          { link = 'Nontext'             })
        utils.hl.set(0, 'FzfLuaBufFlagCur',       {})
        utils.hl.set(0, 'FzfLuaBufName',          {})
        utils.hl.set(0, 'FzfLuaBufNr',            {})
        -- stylua: ignore end
      end)
    end,
  },
}
