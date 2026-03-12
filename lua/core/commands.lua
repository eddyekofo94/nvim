vim.api.nvim_create_user_command('GenColorscheme', function(args)
  local script_path = vim.fn.stdpath('config') .. '/scripts/generate_colorscheme.py'
  local cmd = string.format('python3 %s %s', script_path, args.args)

  local result = vim.fn.system(cmd)
  if vim.v.shell_error == 0 then
    vim.notify('Colorscheme generated: ' .. result, vim.log.levels.INFO)
  else
    vim.notify('Error: ' .. result, vim.log.levels.ERROR)
  end
end, {
  nargs = '*',
  desc = 'Generate colorscheme from palette',
  complete = function()
    local palettes_dir = vim.fn.stdpath('config') .. '/palettes'
    local palettes = vim.fn.globpath(palettes_dir, '*.lua', true, true)
    local names = {}
    for _, p in ipairs(palettes) do
      table.insert(names, vim.fn.fnamemodify(p, ':t:r'))
    end
    return names
  end,
})

vim.api.nvim_create_user_command('GenColorschemeAll', function()
  local script_path = vim.fn.stdpath('config') .. '/scripts/generate_colorscheme.py'
  local cmd = string.format('python3 %s --all', script_path)

  local result = vim.fn.system(cmd)
  if vim.v.shell_error == 0 then
    vim.notify('All colorschemes generated!', vim.log.levels.INFO)
  else
    vim.notify('Error: ' .. result, vim.log.levels.ERROR)
  end
end, {
  desc = 'Generate all colorschemes from palettes',
})

vim.api.nvim_create_user_command('ListPalettes', function()
  local script_path = vim.fn.stdpath('config') .. '/scripts/generate_colorscheme.py'
  vim.fn.system('python3 ' .. script_path .. ' --list')
end, {
  desc = 'List available palettes',
})
