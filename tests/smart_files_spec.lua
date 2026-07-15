local actions = require "fzf-lua.actions"
local config = require "fzf-lua.config"
local fzf = require "fzf-lua"
local libuv = require "fzf-lua.libuv"
local make_entry = require "fzf-lua.make_entry"

local temp_dirs = {}

local function make_temp_dir()
  local dir = vim.fn.tempname()
  assert.are.equal(1, vim.fn.mkdir(dir, "p"))
  table.insert(temp_dirs, dir)
  return dir
end

describe("Smart Files performance hardening", function()
  local original_cwd
  local original_files
  local original_last_cwd
  local original_live_grep
  local original_oldfiles
  local original_resume_data
  local original_transitioning

  before_each(function()
    temp_dirs = {}
    original_cwd = vim.fn.getcwd(0)
    original_files = fzf.files
    original_last_cwd = vim.g._smart_files_last_cwd
    original_live_grep = fzf.live_grep
    original_oldfiles = vim.deepcopy(vim.v.oldfiles)
    original_resume_data = config.__resume_data
    original_transitioning = vim.g._fzf_transitioning
  end)

  after_each(function()
    fzf.files = original_files
    fzf.live_grep = original_live_grep
    vim.g._smart_files_last_cwd = original_last_cwd
    vim.v.oldfiles = original_oldfiles
    config.__resume_data = original_resume_data
    vim.g._fzf_transitioning = original_transitioning
    vim.api.nvim_set_current_dir(original_cwd)
    for _, dir in ipairs(temp_dirs) do
      vim.fn.delete(dir, "rf")
    end
    temp_dirs = {}
  end)

  it("uses the last useful cwd instead of scanning home", function()
    local last_cwd = make_temp_dir()
    local captured

    vim.api.nvim_cmd({ cmd = "enew", bang = true }, {})
    vim.api.nvim_set_current_dir(vim.env.HOME)
    vim.g._smart_files_last_cwd = last_cwd
    vim.v.oldfiles = {}
    fzf.files = function(opts)
      captured = opts
    end

    fzf.smart_files()

    assert.are.equal(last_cwd, captured.cwd)
  end)

  it("evicts the least recently used cwd cache entry", function()
    local dirs = { make_temp_dir(), make_temp_dir(), make_temp_dir() }
    local files = {}
    local output

    for i, dir in ipairs(dirs) do
      files[i] = vim.fs.joinpath(dir, "recent " .. i .. ".lua")
      vim.fn.writefile({ "return " .. i }, files[i])
    end
    vim.v.oldfiles = files
    fzf.files = function(opts)
      local result = vim
        .system({ "sh", "-c", opts.raw_cmd }, { cwd = opts.cwd, text = true })
        :wait()
      assert.are.equal(0, result.code, result.stderr)
      output = result.stdout
    end

    for _, dir in ipairs(dirs) do
      fzf.smart_files {
        cwd = dir,
        smart_oldfiles_cache_limit = 2,
        smart_oldfiles_cache_ttl_ms = 60000,
      }
    end

    vim.fn.delete(files[1])
    fzf.smart_files {
      cwd = dirs[1],
      smart_oldfiles_cache_limit = 2,
      smart_oldfiles_cache_ttl_ms = 60000,
    }

    assert.is_nil(output:find("recent 1.lua", 1, true))
  end)

  it("greps content from cumulatively filtered smart files", function()
    local cwd = make_temp_dir()
    local source_list = vim.fs.joinpath(cwd, "source list")
    local target = vim.fs.joinpath(cwd, "converter.py")
    local unrelated = vim.fs.joinpath(cwd, "README.md")
    local captured

    vim.fn.writefile(
      { "Per-volume OVERRIDES are loaded automatically" },
      target
    )
    vim.fn.writefile({ "OVERRIDES outside the file filter" }, unrelated)
    vim.fn.writefile({ "converter.py", "README.md" }, source_list)

    fzf.live_grep = function(opts)
      captured = opts
    end
    config.__resume_data = {
      last_query = "converter",
      opts = {
        __smart_files = true,
        __smart_full_cmd = "cat " .. vim.fn.shellescape(source_list),
        cwd = cwd,
      },
    }

    actions.toggle_files_grep()
    assert.is_true(vim.wait(1000, function()
      return captured ~= nil
    end))

    local live_action = make_entry.lgrep({ "OVERRIDES" }, captured)
    assert.is_nil(live_action:find("\n", 1, true))
    local command = live_action:gsub("^reload:", "")
    local output = {}
    local stderr = {}
    local exit_code
    local finished = false

    make_entry.preprocess(captured)
    libuv.spawn({
      cwd = cwd,
      cmd = command,
      cb_finish = function(code)
        exit_code = code
        finished = true
      end,
      cb_write = function(data, callback)
        table.insert(output, data)
        callback()
      end,
      cb_err = function(data)
        table.insert(stderr, data)
      end,
    }, function(line)
      return make_entry.file(line, captured)
    end)

    assert.is_true(vim.wait(2000, function()
      return finished
    end))
    assert.are.equal(0, exit_code, table.concat(stderr))
    local transformed_output = table.concat(output)
    assert.is_truthy(transformed_output:find("converter.py", 1, true))
    assert.is_nil(transformed_output:find("README.md", 1, true))
  end)

  it("replaces the previous cumulative file list", function()
    local cwd = make_temp_dir()
    local source_list = vim.fs.joinpath(cwd, "source list")
    local target = vim.fs.joinpath(cwd, "converter.py")
    local captured

    vim.fn.writefile(
      { "Per-volume OVERRIDES are loaded automatically" },
      target
    )
    vim.fn.writefile({ "converter.py" }, source_list)
    fzf.live_grep = function(opts)
      captured = opts
    end
    config.__resume_data = {
      last_query = "converter",
      opts = {
        __smart_files = true,
        __smart_full_cmd = "cat " .. vim.fn.shellescape(source_list),
        cwd = cwd,
      },
    }

    actions.toggle_files_grep()
    assert.is_true(vim.wait(1000, function()
      return captured ~= nil
    end))

    local listfile = captured.cmd:match "if %[%s+-s%s+'([^']+)'%s+%]"
    assert.is_truthy(listfile)
    assert.are.equal(1, vim.fn.filereadable(listfile))

    vim.g._fzf_transitioning = nil
    captured = nil
    actions.toggle_files_grep()
    assert.is_true(vim.wait(1000, function()
      return captured ~= nil
    end))
    local replacement = captured.cmd:match "if %[%s+-s%s+'([^']+)'%s+%]"

    assert.is_truthy(replacement)
    assert.are_not.equal(listfile, replacement)
    assert.are.equal(0, vim.fn.filereadable(listfile))
    assert.are.equal(1, vim.fn.filereadable(replacement))
    vim.fn.delete(replacement)
  end)

  it(
    "keeps an ARG_MAX-sized cumulative file list out of Lua and argv",
    function()
      local cwd = make_temp_dir()
      local source_list = vim.fs.joinpath(cwd, "source list")
      local target = vim.fs.joinpath(cwd, "needle file.txt")
      local writer = assert(io.open(source_list, "w"))
      local relative_target = vim.fs.basename(target)
      local arg_max =
        tonumber(vim.trim(vim.fn.system { "getconf", "ARG_MAX" }))
      local repetitions = math.ceil((arg_max * 2) / (#relative_target + 1))
      local captured

      vim.fn.writefile({ "unique smart files needle" }, target)
      for _ = 1, repetitions do
        writer:write(relative_target, "\n")
      end
      writer:close()
      assert.is_true(vim.uv.fs_stat(source_list).size > arg_max)

      fzf.live_grep = function(opts)
        captured = opts
      end
      config.__resume_data = {
        last_query = "",
        opts = {
          __smart_files = true,
          __smart_full_cmd = "cat " .. vim.fn.shellescape(source_list),
          cwd = cwd,
        },
      }

      actions.toggle_files_grep()
      assert.is_true(vim.wait(1000, function()
        return captured ~= nil
      end))

      assert.is_nil(captured.search_paths)
      assert.is_nil(captured.raw_cmd)
      assert.is_true(type(captured.cmd) == "string")
      assert.is_true(#captured.cmd < arg_max)
      assert.is_nil(captured.cmd:find("<query>", 1, true))

      local command = captured.cmd
        .. " "
        .. vim.fn.shellescape "unique smart files needle"
      local result = vim
        .system({ "sh", "-c", command }, { cwd = cwd, text = true })
        :wait()
      assert.are.equal(0, result.code, result.stderr)
      assert.is_truthy(result.stdout:find("needle file.txt", 1, true))
    end
  )
end)
