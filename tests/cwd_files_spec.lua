local cwd_files = require("plugin.blink-cwd-files")

---Plenary runs each spec file in its own Neovim, so the parent's `+packadd`
---doesn't carry over. Load blink through its real trigger.
local function load_blink()
  if package.loaded["blink.cmp"] then
    return
  end
  -- UIEnter registers the lazy-load handlers; they only exist on the next tick
  vim.api.nvim_exec_autocmds("UIEnter", {})
  vim.wait(1500)
  vim.api.nvim_exec_autocmds("InsertEnter", {})
  assert.is_true(
    vim.wait(10000, function()
      return package.loaded["blink.cmp"] ~= nil
    end),
    "blink.cmp never loaded"
  )
end

---Drive the source the way blink does, synchronously.
---@param line string
---@param col integer 0-indexed cursor offset
---@return table[]
local function complete(line, col)
  local source = cwd_files.new({})
  local called, response = false, nil
  source:get_completions({
    line = line,
    pos = { row = 0, col = col },
  }, function(res)
    called, response = true, res
  end)

  vim.wait(10000, function()
    return called
  end)
  assert.is_true(called, "source never called back")
  return response and response.items or {}
end

---@param items table[]
---@param label string
---@return table?
local function find(items, label)
  for _, item in ipairs(items) do
    if item.label == label then
      return item
    end
  end
end

---Type `keys` into a real cmdline and report what blink resolves while there.
---@param keys string
---@param probe fun(): table
---@return table
local function in_cmdline(keys, probe)
  local seen
  local group = vim.api.nvim_create_augroup("cwd_files_spec", { clear = true })
  vim.api.nvim_create_autocmd("CmdlineChanged", {
    group = group,
    callback = function()
      if vim.fn.getcmdline() == keys:sub(2) then
        seen = probe()
      end
    end,
  })
  vim.fn.feedkeys(keys, "x")
  vim.api.nvim_del_augroup_by_id(group)
  assert.is_not_nil(seen, "cmdline probe never ran for " .. keys)
  return seen
end

describe("@ project file tagging", function()
  before_each(function()
    load_blink()
    cwd_files.invalidate()
    vim.cmd.cd(vim.fn.fnamemodify(vim.env.MYVIMRC, ":h"))
  end)

  it("splits the argument under the cursor on unescaped whitespace", function()
    local arg, start = cwd_files.argument_at("e @lua/core", 11)
    assert.are.equal("@lua/core", arg)
    assert.are.equal(2, start)

    -- escaped space stays inside the argument
    arg, start = cwd_files.argument_at("e @my\\ file", 11)
    assert.are.equal("@my\\ file", arg)
    assert.are.equal(2, start)

    -- cursor before the argument's own text
    arg, start = cwd_files.argument_at("e ", 2)
    assert.are.equal("", arg)
    assert.are.equal(2, start)
  end)

  it("claims only @ arguments", function()
    assert.are.equal("lua/core", cwd_files.query("@lua/core"))
    assert.are.equal("", cwd_files.query("@"))
    assert.is_nil(cwd_files.query("/lua/core"))
    assert.is_nil(cwd_files.query("./lua/core"))
    assert.is_nil(cwd_files.query("~/notes"))
    assert.is_nil(cwd_files.query("lua/core"))
    -- an infix @ is not a tag
    assert.is_nil(cwd_files.query("me@example.com"))
  end)

  it("returns nothing when the argument is not ours", function()
    assert.are.same({}, complete("e lua/core", 10))
    assert.are.same({}, complete("e /etc/hos", 10))
    assert.are.same({}, complete("e ./lua", 7))
  end)

  it("matches fuzzily across path separators", function()
    local items = complete("e @lua/cor/keym", 15)
    assert.is_true(#items > 0, "no items for a cross-segment query")
    assert.is_not_nil(
      find(items, "lua/core/keymaps.lua"),
      "cross-segment query did not reach a nested file"
    )
  end)

  it("reaches nested files from a bare basename query", function()
    local items = complete("e @keymaps", 10)
    assert.is_not_nil(find(items, "lua/core/keymaps.lua"))
  end)

  it("consumes the @ and inserts a usable path", function()
    local items = complete("e @lua/core/keym", 16)
    local item = find(items, "lua/core/keymaps.lua")
    assert.is_not_nil(item)
    ---@cast item table
    assert.are.equal("./lua/core/keymaps.lua", item.textEdit.newText)
  end)

  it("inserts a real path, unescaped in a buffer", function()
    local abs = vim.fs.joinpath(cwd_files.root(), "lua/my file.lua")
    assert.are.equal("./lua/my file.lua", cwd_files.insert_text(abs, false))
    assert.are.equal("./lua/my\\ file.lua", cwd_files.insert_text(abs, true))
  end)

  it("replaces the whole argument, including text after the cursor", function()
    local items = complete("e @lua/core/keym", 16)
    local item = find(items, "lua/core/keymaps.lua")
    assert.is_not_nil(item)
    ---@cast item table
    assert.are.equal(2, item.textEdit.insert.start.character)
    assert.are.equal(16, item.textEdit.insert["end"].character)

    -- cursor mid-path: the tail right of the cursor is part of the replacement
    items = complete("e @lua/core/keym.lua", 16)
    item = find(items, "lua/core/keymaps.lua")
    assert.is_not_nil(item)
    ---@cast item table
    assert.are.equal(20, item.textEdit.replace["end"].character)
  end)

  it(
    "pins filterText to blink's keyword so blink keeps our ranking",
    function()
      local line = "e @lua/core/keym"
      local items = complete(line, #line)
      assert.is_true(#items > 0)

      local fuzzy = require("blink.cmp.fuzzy")
      local keyword_start, keyword_end =
        fuzzy.get_keyword_range(line, #line, false)
      local keyword = line:sub(keyword_start + 1, keyword_end)

      for idx, item in ipairs(items) do
        assert.are.equal(keyword, item.filterText)
        -- rank is carried by sortText alone, since identical filterText makes
        -- every item score the same in blink's matcher
        assert.are.equal(string.format("%06d", idx), item.sortText)
      end
    end
  )

  it("marks directories and completes them with a trailing slash", function()
    local items = complete("e @lua/core", 11)
    local item = find(items, "lua/core/")
    assert.is_not_nil(item)
    ---@cast item table
    assert.are.equal("./lua/core/", item.textEdit.newText)
    assert.are.equal(
      require("blink.cmp.types").CompletionItemKind.Folder,
      item.kind
    )
  end)

  it("completes a buffer line", function()
    local items = complete("local p = @lua/cor/keym", 23)
    assert.is_not_nil(find(items, "lua/core/keymaps.lua"))
  end)

  it("is active in a buffer and shows only files", function()
    local sources = require("blink.cmp.sources.lib")
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local p = @lua/cor" })

    vim.api.nvim_win_set_cursor(0, { 1, 18 })
    assert.is_true(cwd_files.is_active())
    assert.are.same(
      { "cwd_files" },
      sources.get_enabled_provider_ids("default")
    )

    -- cursor before the `@`: ordinary completion
    vim.api.nvim_win_set_cursor(0, { 1, 8 })
    assert.is_false(cwd_files.is_active())
    assert.is_true(
      vim.tbl_contains(sources.get_enabled_provider_ids("default"), "path")
    )

    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("is the source blink picks inside a real cmdline", function()
    local sources = require("blink.cmp.sources.lib")

    assert.are.same(
      { "cwd_files" },
      in_cmdline(":e @lua/core", function()
        return sources.get_enabled_provider_ids("cmdline")
      end)
    )

    assert.are.same(
      { "cmdline", "path" },
      in_cmdline(":e ./lua/core", function()
        return sources.get_enabled_provider_ids("cmdline")
      end)
    )
  end)
end)
