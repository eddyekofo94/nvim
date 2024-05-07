return function(_, opts)
  require("which-key").setup(opts)
  require("utils.keymaps").which_key_register()
end
