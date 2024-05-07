local worktree = require "git-worktree"
local utils = require "utils.keymaps"
local Buffer = require "utils.buffer"
local keymap = utils.set_keymap

worktree.setup {
  change_directory_command = "cd", -- default: "cd",
  update_on_change = true, -- default: true,
  update_on_change_command = "e .", -- default: "e .",
  clearjumps_on_change = true, -- default: true,
  autopush = false, -- default: false,
}

-- require("telescope").load_extension("git_worktree")
--
-- keymap_set("n", "<leader>gwc", function()
--   require("telescope").extensions.git_worktree.create_git_worktree()
-- end, "Git Worktree create")
--
-- keymap_set("n", "<Leader>gww", function()
--   require("telescope").extensions.git_worktree.git_worktrees()
-- end, "Git worktree list")

worktree.on_tree_change(function(op, metadata)
  if op == worktree.Operations.Switch then
    utils.log(
      "Switched from " .. metadata.prev_path .. " to " .. metadata.path,
      "Git Worktree"
    )
    -- vim.cmd([[BufOnly]])
    Buffer.close_all_buffers()
    vim.cmd "e"
  end
end)
