---@type pack.spec
return {
  src = 'https://github.com/echasnovski/mini.icons',
  data = {
    postload = function()
      package.preload['nvim-web-devicons'] = function()
        package.loaded['nvim-web-devicons'] = {}
        require('mini.icons').mock_nvim_web_devicons()
        return package.loaded['nvim-web-devicons']
      end
    end,
  },
}
