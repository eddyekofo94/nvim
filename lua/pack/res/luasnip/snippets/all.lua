local M = {}
local us = require('utils.snip.snips')
local conds = require('utils.snip.conds')
local ls = require('luasnip')
local i = ls.insert_node
local f = ls.function_node
local fmt = require('luasnip.extras.fmt').fmt

-- Helper to get comment leader from Neovim's buffer options
local function get_comment_leader()
  local cs = vim.bo.commentstring
  return cs:gsub('%%s', ''):gsub('%s+$', '') .. ' '
end

local todos = {
  'fix',
  'break',
  'todo',
  'info',
  'disabled',
  'hack',
  'example',
  'warn',
  'clean_up',
  'debug',
  'perf',
  'review',
  'note',
  'test',
  'bug',
  'refc',
  'question',
}

M.snippets = {}

for _, todo in ipairs(todos) do
  local label = todo:upper():gsub('_', '')

  table.insert(
    M.snippets,
    us.ms(
      {
        { trig = todo },
        { trig = todo:sub(1, 1):upper() .. todo:sub(2) },
        common = {
          desc = label .. ' comment',
          condition = conds.in_ft({ '', 'text' })
            + conds.in_ft('markdown') * conds.in_normalzone
            + conds.in_syngroup('Comment')
            + conds.in_tsnode(
              { 'source', 'comment', 'curly_group' },
              { ignore_injections = false }
            ),
        },
      },
      fmt([[{} {}: ({}) {}]], {
        f(get_comment_leader), -- Dynamically inserts -- or // or #
        label, -- Inserts TODO, FIX, etc.
        f(function()
          return os.date('%Y-%m-%d %H:%M')
        end), -- Timestamp
        i(1), -- Your cursor position
      })
    )
  )
end

return M
