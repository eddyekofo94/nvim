describe("Copilot and Sidekick lifecycle", function()
  it("loads on public triggers and preserves integrations", function()
    vim.api.nvim_exec_autocmds("UIEnter", {})
    assert.is_true(vim.wait(2000, function()
      return package.loaded["sidekick"] ~= nil
    end))

    vim.api.nvim_cmd({ cmd = "enew" }, {})
    vim.bo.filetype = "lua"
    assert.is_nil(package.loaded["copilot"])
    vim.api.nvim_exec_autocmds("InsertEnter", {})

    assert.is_true(vim.wait(2000, function()
      return package.loaded["copilot"] ~= nil
    end))
    assert.are.equal(2, vim.fn.exists(":Copilot"))

    local copilot_config = require("copilot.config")
    assert.are.equal("<C-j>", copilot_config.suggestion.keymap.accept)
    assert.are.equal("<M-]>", copilot_config.suggestion.keymap.next)
    assert.are.equal("<M-[>", copilot_config.suggestion.keymap.prev)
    assert.are.equal("<C-R>", copilot_config.suggestion.keymap.dismiss)
    assert.is_true(copilot_config.filetypes.markdown)
    vim.api.nvim_buf_set_name(0, "/tmp/.env.review")
    assert.is_false(copilot_config.filetypes.sh())
    vim.api.nvim_buf_set_name(0, "/tmp/script.sh")
    assert.is_true(copilot_config.filetypes.sh())

    local sidekick_config = require("sidekick.config")
    assert.is_false(sidekick_config.nes.enabled)
    assert.is_true(sidekick_config.cli.mux.enabled)
    assert.are.equal("tmux", sidekick_config.cli.mux.backend)
    assert.are.equal("terminal", sidekick_config.cli.mux.create)

    for _, lhs in ipairs({
      "<tab>",
      "<leader>aa",
      "<leader>as",
      "<leader>aD",
      "<leader>af",
      "<leader>ap",
      "<leader>ao",
    }) do
      assert.is_not_nil(vim.fn.maparg(lhs, "n", false, true).callback)
    end

    for _, lhs in ipairs({
      "<leader>at",
      "<leader>av",
      "<leader>ad",
      "<leader>ap",
    }) do
      assert.is_not_nil(vim.fn.maparg(lhs, "x", false, true).callback)
    end

    if vim.env.NVIM_COPILOT_LIFECYCLE_MODE == "active" then
      assert.is_true(vim.wait(15000, function()
        local clients = vim.lsp.get_clients({ name = "copilot" })
        local accept = vim.fn.maparg("<C-j>", "i", false, true)
        return #clients == 1
          and clients[1].initialized
          and (accept.callback ~= nil or accept.rhs ~= "")
      end))
    end
  end)
end)
