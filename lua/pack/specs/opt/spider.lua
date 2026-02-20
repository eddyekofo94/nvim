---@type pack.spec
return {
  src = 'https://github.com/chrisgrieser/nvim-spider',
  data = {
    event = 'VeryLazy',
    postload = function()
      require('spider').setup({
        skipInsignificantPunctuation = true,
      })

      local map = require('utils.key').map
      local nxo = { 'n', 'x' }

      map(nxo, 'w', function()
        require('spider').motion('w', { skipInsignificantPunctuation = false })
      end, { desc = 'Spider-w' })
      map(nxo, 'e', function()
        require('spider').motion('e')
      end, { desc = 'Spider-e' })
      map(nxo, 'b', function()
        require('spider').motion('b')
      end, { desc = 'Spider-b' })
      map(nxo, 'ge', function()
        require('spider').motion('ge')
      end, { desc = 'Spider-ge' })
    end,
  },
}
