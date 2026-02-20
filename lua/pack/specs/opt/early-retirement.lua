---@type pack.spec
return {
  src = 'https://github.com/chrisgrieser/nvim-early-retirement',
  data = {
    event = 'VeryLazy',
    postload = function()
      require('early-retirement').setup({
        retirementAgeMins = 15,
        ignoredFiletypes = {},
        ignoreFilenamePattern = '',
        ignoreAltFile = false,
        minimumBufferNum = 2,
        ignoreUnsavedChangesBufs = true,
        ignoreSpecialBuftypes = true,
        ignoreVisibleBufs = true,
        ignoreUnloadedBufs = false,
        notificationOnAutoClose = true,
        deleteBufferWhenFileDeleted = true,
      })
    end,
  },
}
