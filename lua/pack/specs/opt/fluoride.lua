---@type pack.spec
return {
  src = "https://github.com/Sang-it/fluoride",
  data = {
    enabled = false,
    optional = true,
    postload = function()
      require("fluoride").setup()

      vim.keymap.set("n", "<C-n>", "<cmd>Fluoride<cr>", {
        desc = "Open Fluoride",
        silent = true,
      })
    end,
  },
}
