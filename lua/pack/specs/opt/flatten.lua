---@type pack.spec
return {
  src = "https://github.com/willothy/flatten.nvim",
  data = {
    event = "BufReadPre",
    postload = function()
      require("flatten").setup({
        window = {
          open = "current",
        },
        hooks = {
          post_open = function(_, winnr, _, is_blocking)
            if not is_blocking then
              vim.api.nvim_set_current_win(winnr)
            end
          end,
          block_end = function()
            vim.schedule(function()
              vim.cmd("unhide")
            end)
          end,
        },
      })
    end,
  },
}
