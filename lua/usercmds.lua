local create_cmd = vim.api.nvim_create_user_command

-- Update nvim
create_cmd("BatchUpdate", function()
  require("lazy").load {
    plugins = { "lazy.nvim", "mason.nvim", "nvim-treesitter" },
  }
  vim.cmd "MasonUpdate"
  vim.cmd "TSUpdate"
  vim.cmd "Lazy update"
end, {})

-- Command to toggle diagnostics
vim.api.nvim_create_user_command("DiagnosticsToggle", function()
  local current_value = vim.diagnostic.is_disabled()
  if current_value then
    vim.diagnostic.enable()
  else
    vim.diagnostic.disable()
  end
end, {})
