-- return {}
local stl_util = require "ui.statusline"

return { -- Collection of various small independent plugins/modules
  "echasnovski/mini.statusline",
  lazy = false,
  enabled = true,
  config = function()
    local statusline = require "mini.statusline"
    statusline.setup {
      content = {
        active = function()
          local mode, mode_hl = statusline.section_mode { trunc_width = 120 }
          local spell = vim.wo.spell and (statusline.is_truncated(120) and "S" or "SPELL") or ""
          local wrap = vim.wo.wrap and (statusline.is_truncated(120) and "W" or "WRAP") or ""
          local git = statusline.section_git { trunc_width = 75 }
          local diagnostics = statusline.section_diagnostics { trunc_width = 75 }
          -- local filename = statusline.section_filename { trunc_width = 140 }
          local fileinfo = statusline.section_fileinfo { trunc_width = 120 }
          local searchcount = statusline.section_searchcount { trunc_width = 75 }
          -- local location = statusline.section_location { trunc_width = 75 }

          return statusline.combine_groups {
            { hl = mode_hl, strings = { mode, spell, wrap } },
            { hl = "MiniStatuslineInactive", strings = { stl_util.project_name() } },
            { hl = "MiniStatuslineFilename", strings = { stl_util.file_info() } },
            "%<", -- Mark general truncate point
            { hl = "MiniStatuslineDevinfo", strings = { diagnostics } },
            { hl = "String", strings = { stl_util.macro() } },
            { hl = "MiniStatuslineDevinfo" },
            "%=", -- End left alignment
            { hl = "MiniStatuslineInactive", strings = { stl_util.lsp_progress() } },
            "%=",
            { hl = "MiniStatuslineInactive", strings = { stl_util.lsp() } },
            { hl = "MiniStatuslineFilename", strings = { stl_util.info() } },
            { hl = mode_hl, strings = { stl_util.search_count(), stl_util.lineinfo() } },
            -- { hl = "MiniStatuslineFilename", strings = { project_name() } },
          }
        end,
      },
    }
    vim.opt.laststatus = 3
  end,
}

-- local statusline = require "mini.statusline"
-- statusline.setup {
--
--   set_vim_settings = false,
--   use_icons = vim.g.have_nerd_font,
-- }
--
-- -- You can configure sections in the statusline by overriding their
-- -- default behavior. For example, here we set the section for
-- -- cursor location to LINE:COLUMN
-- ---@diagnostic disable-next-line: duplicate-set-field
-- statusline.section_location = function()
--   return "%2l:%-2v"
-- end
