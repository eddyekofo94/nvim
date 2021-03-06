vim.api.nvim_set_keymap("n", "<TAB>", ":BufferNext<CR>", {noremap = true, silent = true})
vim.api.nvim_set_keymap("n", "<S-TAB>", ":BufferPrevious<CR>", {noremap = true, silent = true})
vim.api.nvim_set_keymap("n", "<S-x>", ":BufferClose<CR>", {noremap = true, silent = true})

-- For the current active buffer icon
vim.cmd "hi default link BufferCurrentSign  Normal"

-- For buffers visible but not the current one
vim.cmd "hi default link BufferVisible TabLineSel"

local tree ={}
tree.open = function ()
   require'bufferline.state'.set_offset(31)
   require'nvim-tree'.find_file(true)
end

tree.close = function ()
   require'bufferline.state'.set_offset(0)
   require'nvim-tree'.close()
end

return tree
