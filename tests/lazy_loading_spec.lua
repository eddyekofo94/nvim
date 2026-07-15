describe("vim.pack lazy loading", function()
  it("keeps unrelated optional plugins unloaded after UIEnter", function()
    vim.api.nvim_exec_autocmds("UIEnter", {})

    assert.is_true(vim.wait(2000, function()
      return package.loaded["sidekick"] ~= nil
    end))

    assert.is_nil(package.loaded["mason"])
    assert.is_nil(package.loaded["copilot"])

    local runtime_paths = vim.opt.runtimepath:get()
    for _, plugin in ipairs({ "mason.nvim", "copilot.lua" }) do
      local plugin_path = vim.fs.joinpath(require("utils.pack").root(), plugin)
      assert.is_false(
        vim.tbl_contains(runtime_paths, plugin_path),
        plugin .. " was added to runtimepath by UIEnter"
      )
    end
  end)
end)
