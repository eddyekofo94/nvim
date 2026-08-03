local agent_prompt = require("plugin.agent-prompt")
local cwd_files = require("plugin.blink-cwd-files")

-- The module captures Neovim's startup cwd when it is first required, which
-- the line above just did. Read it the same way so the "cwd is the startup
-- cwd" assertions cannot drift with however the suite was launched.
local repo = vim.uv.cwd()

local tmproot
local prompt_file
local closeout_file
local seed_file

local closeout_lines = {
  "  **Status:** DONE — newer run.",
  "",
  "  Artifacts: `tools/agent_prompt_editor.sh`.",
  "",
  "  **Next move:** run the newer thing.",
  "",
  "  **Ready-to-paste prompt:**",
  "",
  "  ```",
  "  SEEDED PROMPT LINE ONE",
  "  SEEDED PROMPT LINE TWO",
  "  ```",
}

local seed_lines = {
  "  SEEDED PROMPT LINE ONE",
  "  SEEDED PROMPT LINE TWO",
}

---@param path string
---@param lines string[]
local function write(path, lines)
  assert.are.equal(0, vim.fn.writefile(lines, path))
end

---Open `prompt_file` alone in a single window, the way `nvim <file>` leaves it.
---@return integer win
local function open_prompt()
  vim.cmd("silent! only!")
  vim.cmd.edit({ prompt_file, mods = { silent = true } })
  return vim.api.nvim_get_current_win()
end

---@return AgentPrompt.Target
local function target()
  local found = agent_prompt.detect({
    args = { prompt_file },
    closeout = closeout_file,
    seed = seed_file,
    tmpdir = tmproot,
  })
  assert.is_not_nil(found, "detection rejected a valid agent prompt launch")
  ---@cast found AgentPrompt.Target
  return found
end

describe("agent prompt editor", function()
  before_each(function()
    tmproot = vim.fn.tempname()
    assert.are.equal(1, vim.fn.mkdir(tmproot, "p"))
    prompt_file = vim.fs.joinpath(tmproot, "agent-prompt.md")
    closeout_file = vim.fs.joinpath(tmproot, "closeout.md")
    seed_file = vim.fs.joinpath(tmproot, "seed.txt")

    write(prompt_file, {})
    write(closeout_file, closeout_lines)
    write(seed_file, seed_lines)

    vim.cmd("silent! only!")
    vim.cmd.cd(repo)
  end)

  after_each(function()
    vim.cmd("silent! only!")
    vim.cmd("silent! %bwipeout!")
    vim.fn.delete(tmproot, "rf")
  end)

  it("accepts a single prompt file under $TMPDIR", function()
    local found = target()
    assert.are.equal(vim.uv.fs_realpath(prompt_file), found.file)
    assert.are.equal(closeout_file, found.closeout)
    assert.are.equal(seed_file, found.seed)
  end)

  it("reads the closeout, seed and tmpdir from the environment", function()
    local saved = {
      closeout = vim.env.AGENT_CLOSEOUT_FILE,
      seed = vim.env.AGENT_PROMPT_SEED_FILE,
    }
    vim.env.AGENT_CLOSEOUT_FILE = closeout_file
    vim.env.AGENT_PROMPT_SEED_FILE = seed_file

    local found = agent_prompt.detect({ args = { prompt_file } })
    assert.is_not_nil(found, "environment-driven detection failed")
    ---@cast found AgentPrompt.Target
    assert.are.equal(closeout_file, found.closeout)
    assert.are.equal(seed_file, found.seed)

    vim.env.AGENT_CLOSEOUT_FILE = saved.closeout
    vim.env.AGENT_PROMPT_SEED_FILE = saved.seed
  end)

  it("rejects an ordinary file outside $TMPDIR", function()
    local ordinary = "/tmp/agent-prompt-spec-ordinary.md"
    assert.is_nil(agent_prompt.detect({
      args = { ordinary },
      closeout = closeout_file,
      tmpdir = tmproot,
    }))

    -- and a temp-looking path that merely shares a prefix with $TMPDIR
    assert.is_nil(agent_prompt.detect({
      args = { tmproot .. "-sibling/prompt.md" },
      closeout = closeout_file,
      tmpdir = tmproot,
    }))
  end)

  it("rejects launches that are not a lone prompt file", function()
    -- an ordinary editing session that happens to inherit the variable
    assert.is_nil(agent_prompt.detect({
      args = { prompt_file, "lua/core/options.lua" },
      closeout = closeout_file,
      tmpdir = tmproot,
    }))
    assert.is_nil(agent_prompt.detect({
      args = {},
      closeout = closeout_file,
      tmpdir = tmproot,
    }))
  end)

  it("rejects a missing or unreadable closeout", function()
    assert.is_nil(agent_prompt.detect({
      args = { prompt_file },
      closeout = vim.fs.joinpath(tmproot, "absent.md"),
      tmpdir = tmproot,
    }))
    assert.is_nil(agent_prompt.detect({
      args = { prompt_file },
      closeout = "",
      tmpdir = tmproot,
    }))
  end)

  it("keeps the prompt window on the startup cwd, not $TMPDIR", function()
    local win = open_prompt()
    agent_prompt.open(target())

    assert.are.equal(win, vim.api.nvim_get_current_win())
    assert.are.equal(repo, vim.fn.getcwd(win))

    -- `@` completion resolves through the window, so it targets the repo the
    -- agent was launched from rather than the temp tree
    assert.are.equal(repo, cwd_files.root())
  end)

  it("exempts the prompt buffer from the auto_cwd autocmd", function()
    local win = open_prompt()

    -- control: an unmarked buffer under $TMPDIR really is moved by auto_cwd,
    -- so the exemption below is doing the work
    assert.are_not.equal(repo, vim.fn.getcwd(win))

    agent_prompt.open(target())

    local buf = vim.api.nvim_win_get_buf(win)
    assert.is_true(agent_prompt.is_prompt_buf(buf))

    -- auto_cwd would otherwise lcd this window into $TMPDIR on re-entry
    vim.api.nvim_exec_autocmds("BufEnter", { buffer = buf })
    assert.are.equal(repo, vim.fn.getcwd(win))

    -- change_to_cur_dir is the other rooting autocmd, and it defers its lcd
    -- with vim.schedule — it lands after the prompt editor has laid out, so
    -- drain the scheduler before believing the cwd survived
    vim.api.nvim_exec_autocmds("BufWinEnter", { buffer = buf })
    vim.wait(50)
    assert.are.equal(repo, vim.fn.getcwd(win))
  end)

  it("seeds an empty prompt as one change a single undo reverses", function()
    local win = open_prompt()
    local buf = vim.api.nvim_win_get_buf(win)
    assert.is_true(agent_prompt.open(target()) ~= nil)

    assert.are.same(seed_lines, vim.api.nvim_buf_get_lines(buf, 0, -1, false))

    vim.api.nvim_win_call(win, function()
      vim.cmd.undo()
    end)
    assert.are.same({ "" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
  end)

  it("leaves a non-empty handed-over prompt untouched", function()
    local handed_over = { "already written by the agent", "second line" }
    write(prompt_file, handed_over)

    local win = open_prompt()
    local buf = vim.api.nvim_win_get_buf(win)
    agent_prompt.open(target())

    assert.are.same(handed_over, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    assert.is_false(vim.bo[buf].modified)
  end)

  it("leaves the prompt empty when no seed was captured", function()
    local win = open_prompt()
    local buf = vim.api.nvim_win_get_buf(win)

    local found = agent_prompt.detect({
      args = { prompt_file },
      closeout = closeout_file,
      seed = vim.fs.joinpath(tmproot, "absent-seed.txt"),
      tmpdir = tmproot,
    })
    assert.is_not_nil(found)
    ---@cast found AgentPrompt.Target
    agent_prompt.open(found)

    assert.are.same({ "" }, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    assert.is_true(vim.api.nvim_win_is_valid(win))
  end)

  it("shows the whole closeout in a read-only window on the right", function()
    local prompt_win = open_prompt()
    local closeout_win = agent_prompt.open(target())
    assert.is_not_nil(closeout_win)
    ---@cast closeout_win integer

    local buf = vim.api.nvim_win_get_buf(closeout_win)
    assert.are.same(
      closeout_lines,
      vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    )

    -- the ready-to-paste block is included: Eddy yanks from it
    assert.is_true(
      vim.tbl_contains(
        vim.api.nvim_buf_get_lines(buf, 0, -1, false),
        "  SEEDED PROMPT LINE TWO"
      )
    )

    assert.is_false(vim.bo[buf].modifiable)
    assert.is_false(vim.bo[buf].buflisted)
    assert.are.equal("nofile", vim.bo[buf].buftype)

    local _, prompt_col = unpack(vim.api.nvim_win_get_position(prompt_win))
    local _, closeout_col = unpack(vim.api.nvim_win_get_position(closeout_win))
    assert.is_true(
      closeout_col > prompt_col,
      "closeout window is not right of the prompt"
    )

    -- focus never leaves the prompt
    assert.are.equal(prompt_win, vim.api.nvim_get_current_win())
  end)
end)
