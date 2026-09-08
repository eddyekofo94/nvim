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
    -- A live closeout autocmd outlasting its test would fire on the teardown
    -- below and quit the whole run, taking the remaining specs with it.
    for _, au in ipairs(vim.api.nvim_get_autocmds({ event = "WinClosed" })) do
      if
        au.group_name and au.group_name:find("AgentPromptCloseout", 1, true)
      then
        pcall(vim.api.nvim_del_augroup_by_id, au.group)
      end
    end
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

  it("accepts a prompt file under /tmp, outside $TMPDIR", function()
    -- Claude Code writes under /tmp (/private/tmp once resolved), a different
    -- tree from the /var/folders $TMPDIR Codex and Pi use
    local claude_root = "/tmp/agent-prompt-spec-claude"
    assert.are.equal(1, vim.fn.mkdir(claude_root, "p"))
    local claude_prompt = vim.fs.joinpath(claude_root, "prompt.md")
    write(claude_prompt, {})

    assert.is_not_nil(
      agent_prompt.detect_prompt_file({
        args = { claude_prompt },
        agent = true,
      }),
      "a /tmp prompt file was rejected, so its window falls back to auto_cwd"
    )

    vim.fn.delete(claude_root, "rf")
  end)

  it("guards the cwd even when no closeout was captured", function()
    assert.is_nil(
      agent_prompt.detect({
        args = { prompt_file },
        closeout = vim.fs.joinpath(tmproot, "absent.md"),
        tmpdir = tmproot,
      }),
      "a missing closeout must not produce a split"
    )

    assert.are.equal(
      vim.uv.fs_realpath(prompt_file),
      agent_prompt.detect_prompt_file({
        args = { prompt_file },
        tmpdir = tmproot,
        agent = true,
      })
    )
  end)

  it("ignores a lone temp file outside an agent launch", function()
    assert.is_nil(agent_prompt.detect_prompt_file({
      args = { prompt_file },
      tmpdir = tmproot,
      agent = false,
    }))
  end)

  it("recognises every agent runtime, not just Claude Code", function()
    -- Only Claude Code exports AI_AGENT, so each of the others has to be
    -- recognised on a marker of its own.
    local markers = {
      { AI_AGENT = "claude-code_2-1-220_agent" },
      { CLAUDECODE = "1" },
      { CLAUDE_CODE_ENTRYPOINT = "cli" },
      { CODEX_THREAD_ID = "0199abcd" },
      { OPENCODE = "1" },
      { OPENCODE_CLIENT = "acp" },
      { PI_CODING_AGENT_DIR = "/tmp/pi/config" },
      { PI_PILOT_CONTROL_DIR = "/tmp/pi/control" },
      { CURSOR_AGENT = "1" },
      { GEMINI_CLI = "1" },
      { AIDER_MODEL = "gpt" },
    }
    for _, env in ipairs(markers) do
      local name = next(env)
      assert.is_not_nil(
        agent_prompt.detect_prompt_file({
          args = { prompt_file },
          tmpdir = tmproot,
          env = env,
        }),
        ("%s was not recognised as an agent launch"):format(name)
      )
    end
  end)

  it("ignores an environment with no agent marker", function()
    assert.is_nil(agent_prompt.detect_prompt_file({
      args = { prompt_file },
      tmpdir = tmproot,
      -- variables that merely share a prefix with an agent's own
      env = { EDITOR = "nvim", PI_HOLE = "1", CODEXIS = "1", HOME = "/home" },
    }))
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
    vim.api.nvim_exec_autocmds("BufEnter", { buf = buf })
    assert.are.equal(repo, vim.fn.getcwd(win))

    -- change_to_cur_dir is the other rooting autocmd, and it defers its lcd
    -- with vim.schedule — it lands after the prompt editor has laid out, so
    -- drain the scheduler before believing the cwd survived
    vim.api.nvim_exec_autocmds("BufWinEnter", { buf = buf })
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

    -- Default placement is below: a prompt is written in long lines, so a
    -- right-hand split halves the width available to both halves.
    local prompt_row = unpack(vim.api.nvim_win_get_position(prompt_win))
    local closeout_row = unpack(vim.api.nvim_win_get_position(closeout_win))
    assert.is_true(
      closeout_row > prompt_row,
      "closeout window is not below the prompt"
    )

    -- focus never leaves the prompt
    assert.are.equal(prompt_win, vim.api.nvim_get_current_win())
  end)

  it("restores the closeout's share of the frame after a resize", function()
    local prompt_win = open_prompt()
    local closeout_win = agent_prompt.open(target())
    assert.is_not_nil(closeout_win)
    ---@cast closeout_win integer

    local frame = vim.api.nvim_win_get_height(closeout_win)
      + vim.api.nvim_win_get_height(prompt_win)
    local want = vim.api.nvim_win_get_height(closeout_win)

    -- Stands in for the squeeze a Herdr split forces on a pane too short to
    -- honour `winfixheight`: the closeout loses rows it never gets back.
    vim.api.nvim_win_resize(closeout_win, -1, 2)
    assert.are_not.equal(want, vim.api.nvim_win_get_height(closeout_win))

    vim.cmd("doautocmd VimResized")
    vim.wait(200, function()
      return vim.api.nvim_win_get_height(closeout_win) ~= 2
    end)

    local got = vim.api.nvim_win_get_height(closeout_win)
    assert.is_true(
      math.abs(got - want) <= 1,
      ("closeout kept %d of %d rows, wanted about %d"):format(got, frame, want)
    )
  end)

  it("closes the closeout when the prompt window closes", function()
    local prompt_win = open_prompt()
    -- An extra window stands in for "not the last one on screen", so the
    -- close path is exercised without quitting the test session. It has to
    -- come after open_prompt, which starts with `only!`.
    vim.cmd.split({ mods = { silent = true } })
    vim.api.nvim_set_current_win(prompt_win)

    local closeout_win = agent_prompt.open(target())
    assert.is_not_nil(closeout_win)
    ---@cast closeout_win integer

    vim.api.nvim_win_close(prompt_win, true)
    vim.wait(200, function()
      return not vim.api.nvim_win_is_valid(closeout_win)
    end)

    assert.is_false(
      vim.api.nvim_win_is_valid(closeout_win),
      "closeout outlived the prompt window"
    )
  end)

  it("treats a float as no company when the prompt window closes", function()
    -- A notification, picker or diagnostic float is counted by
    -- `nvim_tabpage_list_wins` but cannot hold the pane open. Counting one as
    -- company left `:q` on the prompt with the closeout still on screen and
    -- Neovim still running -- the reference stranded, which is what Eddy hit.
    local prompt_win = open_prompt()
    vim.cmd.split({ mods = { silent = true } })
    vim.api.nvim_set_current_win(prompt_win)

    local closeout_win = agent_prompt.open(target())
    assert.is_not_nil(closeout_win)
    ---@cast closeout_win integer

    local float =
      vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), false, {
        relative = "editor",
        row = 1,
        col = 1,
        width = 10,
        height = 3,
      })

    vim.api.nvim_win_close(prompt_win, true)
    vim.wait(200, function()
      return not vim.api.nvim_win_is_valid(closeout_win)
    end)
    pcall(vim.api.nvim_win_close, float, true)

    assert.is_false(
      vim.api.nvim_win_is_valid(closeout_win),
      "a float kept the closeout alive after the prompt closed"
    )
  end)

  it("puts the closeout on the right when asked", function()
    vim.g.agent_prompt_split = "right"
    local prompt_win = vim.api.nvim_get_current_win()
    local closeout_win = agent_prompt.open(target())
    vim.g.agent_prompt_split = nil

    local _, prompt_col = unpack(vim.api.nvim_win_get_position(prompt_win))
    local _, closeout_col = unpack(vim.api.nvim_win_get_position(closeout_win))
    assert.is_true(
      closeout_col > prompt_col,
      "closeout window is not right of the prompt"
    )
  end)
end)
