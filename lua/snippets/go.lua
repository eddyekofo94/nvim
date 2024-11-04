-- As defining all of the snippet-constructors (s, c, t, ...) in every file is rather cumbersome,
-- luasnip will bring some globals into scope for executing these files.
-- defined by SNIP_ENV in setup
-- require("luasnip.loaders.from_lua").lazy_load()
-- local env = SNIP_ENV

local M = {}
local un = require "snippets.utils.nodes"
local uf = require "snippets.utils.funcs"
local us = require "snippets.utils.snips"
local ls = require "luasnip"
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node

M = {
  us.msn(
    {
      { trig = "fe" },
      { trig = "fme" },
    },
    un.fmtad('fmt.Errorf("<text>", <value>)', {
      text = i(1),
      value = i(2),
    })
  ),
  us.msn(
    {
      { trig = "ff" },
      { trig = "fmP" },
    },
    un.fmtad('fmt.Println("<text>")', {
      text = i(1),
    })
  ),
  us.msn(
    {
      { trig = "fff" },
      { trig = "fmPf" },
    },
    un.fmtad('fmt.Printf("<text>",<value>)', {
      text = i(1),
      value = i(2),
    })
  ),
  us.msn(
    {
      { trig = "lpf" },
      { trig = "logrf" },
    },
    un.fmtad('logrus.Printf("<text>",<value>)', {
      text = i(1),
      value = i(2),
    })
  ),
  us.msn(
    {
      { trig = "sf" },
      { trig = "fmsf" },
    },
    un.fmtad('logrus.Sprintf("<text>",<value>)', {
      text = i(1),
      value = i(2),
    })
  ),
  us.msn({
    { trig = "rt" },
    { trig = "ret" },
    { trig = "return" },
  }, {
    t "return ",
    i(1, "nil"),
  }),
}

return M
