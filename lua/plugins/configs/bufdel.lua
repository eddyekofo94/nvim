local utils = require "utils.keymaps"
local maps = require("utils").empty_map_table()

-- maps.n["<leader>"] = {
--   function()
--     require("telescope").builtins.find_files()
--   end,
--   desc = "find files",
-- }

utils.set_mappings(maps)
