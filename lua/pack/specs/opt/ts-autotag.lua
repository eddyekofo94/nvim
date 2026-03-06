---@type pack.spec
return {
  src = 'https://github.com/tronikelis/ts-autotag.nvim',
  data = {
    events = 'InsertEnter',
    postload = function()
      require('ts-autotag').setup({
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
      })
    end,
  },
}
