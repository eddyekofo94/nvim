---@type pack.spec
return {
  src = "https://github.com/zbirenbaum/copilot.lua",
  data = {
    cmd = { "Copilot" },
    events = { event = "InsertEnter" },
    postload = function()
      require("copilot").setup({
        filetypes = {
          markdown = true,
          sh = function()
            if
              string.match(
                vim.fs.basename(vim.api.nvim_buf_get_name(0)),
                "^%.env.*"
              )
            then
              return false
            end
            return true
          end,
        },
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            accept = "<C-j>",
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-R>",
          },
        },
      })

      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("config.copilot_lifecycle", {
          clear = true,
        }),
        callback = function()
          local ok, copilot_client = pcall(require, "copilot.client")
          if not ok then
            return
          end
          local client = copilot_client.get()
          pcall(copilot_client.teardown)
          if client then
            pcall(client.stop, client, true)
          end
        end,
        desc = "Cancel Copilot startup and stop its LSP process on exit",
      })
    end,
  },
}
