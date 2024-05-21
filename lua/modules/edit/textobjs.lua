local utils = require "utils.general"
return { -- pattern-based textobjs
  "chrisgrieser/nvim-various-textobjs",
  event = "VeryLazy",
  enabled = false,
  keys = {
    { "<Space>", "<cmd>lua require('various-textobjs').subword('inner')<CR>", mode = "o", desc = "󱡔 inner subword" },
    { "a<Space>", "<cmd>lua require('various-textobjs').subword('outer')<CR>", mode = { "o", "x" }, desc = "󱡔 outer subword" },

    { "iv", "<cmd>lua require('various-textobjs').value('inner')<CR>", mode = { "x", "o" }, desc = "󱡔 inner value" },
    { "av", "<cmd>lua require('various-textobjs').value('outer')<CR>", mode = { "x", "o" }, desc = "󱡔 outer value" },
    -- INFO `ik` defined via treesitter to exclude `local` and `let`;
    { "ak", "<cmd>lua require('various-textobjs').key('outer')<CR>", mode = { "x", "o" }, desc = "󱡔 outer key" },

    { "pp", "<cmd>lua require('various-textobjs').lastChange()<CR>", mode = "o", desc = "󱡔 last paste/change" },
    { "gg", "<cmd>lua require('various-textobjs').entireBuffer()<CR>", mode = { "x", "o" }, desc = "󱡔 entire buffer" },

    { "n", "<cmd>lua require('various-textobjs').nearEoL()<CR>", mode = "o", desc = "󱡔 near EoL" },
    { "m", "<cmd>lua require('various-textobjs').toNextClosingBracket()<CR>", mode = { "o", "x" }, desc = "󱡔 to next closing bracket" },
    { "w", "<cmd>lua require('various-textobjs').toNextQuotationMark()<CR>", mode = "o", desc = "󱡔 to next quote", nowait = true },
    { "b", "<cmd>lua require('various-textobjs').anyBracket('inner')<CR>", mode = "o", desc = "󱡔 inner anyBracket" },
    { "B", "<cmd>lua require('various-textobjs').anyBracket('outer')<CR>", mode = "o", desc = "󱡔 outer anyBracket" },
    { "k", "<cmd>lua require('various-textobjs').anyQuote('inner')<CR>", mode = "o", desc = "󱡔 inner anyQuote" },
    { "K", "<cmd>lua require('various-textobjs').anyQuote('outer')<CR>", mode = "o", desc = "󱡔 outer anyQuote" },
    { "iR", "<cmd>lua require('various-textobjs').doubleSquareBrackets('inner')<CR>", mode = { "x", "o" }, desc = "󱡔 inner wikilink" },
    { "aR", "<cmd>lua require('various-textobjs').doubleSquareBrackets('outer')<CR>", mode = { "x", "o" }, desc = "󱡔 outer wikilink" },

    -- INFO not setting in visual mode, to keep visual block mode replace
    { "rp", "<cmd>lua require('various-textobjs').restOfParagraph()<CR>", mode = "o", desc = "󱡔 rest of paragraph" },
    { "ri", "<cmd>lua require('various-textobjs').restOfIndentation()<CR>", mode = "o", desc = "󱡔 rest of indentation" },
    { "rg", "G", mode = "o", desc = "󱡔 rest of buffer" },

    { "ge", "<cmd>lua require('various-textobjs').diagnostic()<CR>", mode = { "x", "o" }, desc = "󱡔 diagnostic" },
    { "L", "<cmd>lua require('various-textobjs').url()<CR>", mode = "o", desc = "󱡔 link" },
    { "o", "<cmd>lua require('various-textobjs').column()<CR>", mode = "o", desc = "󱡔 column" },

    { "in", "<cmd>lua require('various-textobjs').number('inner')<CR>", mode = { "x", "o" }, desc = "󱡔 inner notebookCell" },
    { "an", "<cmd>lua require('various-textobjs').number('outer')<CR>", mode = { "x", "o" }, desc = "󱡔 outer notebookCell" },

    { "ii", "<cmd>lua require('various-textobjs').indentation('inner', 'inner')<CR>", mode = { "x", "o" }, desc = "󱡔 inner indent" },
    { "ai", "<cmd>lua require('various-textobjs').indentation('outer', 'outer')<CR>", mode = { "x", "o" }, desc = "󱡔 outer indent" },
    { "aj", "<cmd>lua require('various-textobjs').indentation('outer', 'inner')<CR>", mode = { "x", "o" }, desc = "󱡔 top-border indent" },
    { "ig", "<cmd>lua require('various-textobjs').greedyOuterIndentation('inner')<CR>", mode = { "x", "o" }, desc = "󱡔 inner greedy indent" },
    { "ag", "<cmd>lua require('various-textobjs').greedyOuterIndentation('outer')<CR>", mode = { "x", "o" }, desc = "󱡔 outer greedy indent" },

    { "i.", "<cmd>lua require('various-textobjs').chainMember('inner')<CR>", mode = { "x", "o" }, desc = "󱡔 inner indent" },
    { "a.", "<cmd>lua require('various-textobjs').chainMember('outer')<CR>", mode = { "x", "o" }, desc = "󱡔 outer indent" },

    { "u", "<cmd>lua require('various-textobjs').multiCommentedLines()<CR>", mode = "o", desc = "󱡔 multi-line-comment" },
    { "guu", "guu" }, -- do not use `u` as textobject when using `guu`

    -- python
    { "iy", "<cmd>lua require('various-textobjs').pyTripleQuotes('inner')<CR>", ft = "python", mode = { "x", "o" }, desc = "󱡔 inner tripleQuotes" },
    { "ay", "<cmd>lua require('various-textobjs').pyTripleQuotes('outer')<CR>", ft = "python", mode = { "x", "o" }, desc = "󱡔 outer tripleQuotes" },

    -- markdown
    { "iE", "<cmd>lua require('various-textobjs').mdFencedCodeBlock('inner')<CR>", mode = { "x", "o" }, ft = "markdown", desc = "󱡔 inner CodeBlock" },
    { "aE", "<cmd>lua require('various-textobjs').mdFencedCodeBlock('outer')<CR>", mode = { "x", "o" }, ft = "markdown", desc = "󱡔 outer CodeBlock" },
    { "il", "<cmd>lua require('various-textobjs').mdlink('inner')<CR>", mode = { "x", "o" }, ft = "markdown", desc = "󱡔 inner md link" },
    { "al", "<cmd>lua require('various-textobjs').mdlink('outer')<CR>", mode = { "x", "o" }, ft = "markdown", desc = "󱡔 outer md link" },
    { "if", "<cmd>lua require('various-textobjs').mdEmphasis('inner')<CR>", mode = { "x", "o" }, ft = "markdown", desc = "󱡔 inner md formatting" },
    { "af", "<cmd>lua require('various-textobjs').mdEmphasis('outer')<CR>", mode = { "x", "o" }, ft = "markdown", desc = "󱡔 outer md formatting" },

    -- css
    { "is", "<cmd>lua require('various-textobjs').cssSelector('inner')<CR>", mode = { "x", "o" }, ft = "css", desc = "󱡔 inner selector" },
    { "as", "<cmd>lua require('various-textobjs').cssSelector('outer')<CR>", mode = { "x", "o" }, ft = "css", desc = "󱡔 outer selector" },
    { "i#", "<cmd>lua require('various-textobjs').cssColor('inner')<CR>", mode = { "x", "o" }, ft = "css", desc = "󱡔 inner color" },
    { "a#", "<cmd>lua require('various-textobjs').cssColor('outer')<CR>", mode = { "x", "o" }, ft = "css", desc = "󱡔 outer color" },

    -- shell
    { "pi", "<cmd>lua require('various-textobjs').shellPipe('inner')<CR>", mode = "o", ft = "sh", desc = "󱡔 inner pipe" },

    { -- delete surrounding indentation
      "dsi",
      function()
        require("various-textobjs").indentation("outer", "outer")
        local indentationFound = vim.fn.mode():find "V"
        if not indentationFound then
          return
        end

        utils.normal "<" -- dedent indentation
        local endBorderLn = vim.api.nvim_buf_get_mark(0, ">")[1]
        local startBorderLn = vim.api.nvim_buf_get_mark(0, "<")[1]
        vim.cmd(tostring(endBorderLn) .. " delete") -- delete end first so line index is not shifted
        vim.cmd(tostring(startBorderLn) .. " delete")
      end,
      desc = " Delete surrounding indent",
    },
    { -- yank surrounding inner indentation
      "ysii", -- `ysi` would conflict with `ysib` and other textobs
      function()
        -- identify start- and end-border
        local startPos = vim.api.nvim_win_get_cursor(0)
        require("various-textobjs").indentation("outer", "outer")
        local indentationFound = vim.fn.mode():find "V"
        if not indentationFound then
          return
        end
        utils.normal "V" -- leave visual mode so <> marks are set
        vim.api.nvim_win_set_cursor(0, startPos) -- restore (= sticky)

        -- copy them into the + register
        local startLn = vim.api.nvim_buf_get_mark(0, "<")[1] - 1
        local endLn = vim.api.nvim_buf_get_mark(0, ">")[1] - 1
        local startLine = vim.api.nvim_buf_get_lines(0, startLn, startLn + 1, false)[1]
        local endLine = vim.api.nvim_buf_get_lines(0, endLn, endLn + 1, false)[1]
        vim.fn.setreg("+", startLine .. "\n" .. endLine .. "\n")

        -- highlight yanked text
        local ns = vim.api.nvim_create_namespace "ysi"
        vim.highlight.range(0, ns, "IncSearch", { startLn, 0 }, { startLn, -1 })
        vim.highlight.range(0, ns, "IncSearch", { endLn, 0 }, { endLn, -1 })
        vim.defer_fn(function()
          vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
        end, 1000)
      end,
      desc = "󰅍 Yank surrounding indent",
    },
    { -- indent last paste
      "P",
      function()
        require("various-textobjs").lastChange()
        local changeFound = vim.fn.mode():find "v"
        if changeFound then
          utils.normal ">"
        end
      end,
      desc = " Indent Last Paste",
    },
    { -- open URL (forward seeking)
      "gx",
      function()
        require("various-textobjs").url()
        local foundURL = vim.fn.mode():find "v"
        if foundURL then
          utils.normal '"zy'
          local url = vim.fn.getreg "z"
          vim.fn.system { "open", url }
        end
      end,
      desc = "󰌹 Smart URL Opener",
    },
  },
}
