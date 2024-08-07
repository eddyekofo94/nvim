return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  enabled = true,
  init = function()
    require("utils.general").add_command("[MISC] Restore Workspace Session for CWD", function()
      require("persistence").load()
    end, { add_custom = true })
  end,
  config = true,
}
