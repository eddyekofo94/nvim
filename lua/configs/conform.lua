local options = {
  -- Map of filetype to formatters
  formatters_by_ft = {
    lua = { "stylua" },
    -- Conform will run multiple formatters sequentially
    go = { "gofumpt", "goimports_reviser", "gofmt", "golines" }, -- "goimports", "gofmt"
    json = { "jq" },
    yaml = { "prettier" },
    -- Use a sub-list to run only the first available formatter
    javascript = { "prettierd", "prettier" },
    -- You can use a function here to determine the formatters dynamically
    python = function(bufnr)
      if require("conform").get_formatter_info("ruff_format", bufnr).available then
        return { "ruff_format" }
      else
        return { "autopep8", "isort", "black" }
      end
    end,
    sh = {
      "beautysh",
      "shfmt",
    },
    fish = { "fish_indent" },
    zsh = {
      "beautysh",
    },
    -- Use the "*" filetype to run formatters on all filetypes.
    ["*"] = { "codespell" },
    -- Use the "_" filetype to run formatters on filetypes that don't
    -- have other formatters configured.
    -- ["_"] = { "trim_whitespace" },
  },

  -- If this is set, Conform will run the formatter on save.
  -- It will pass the table to conform.format().
  -- This can also be a function that returns the table.
  format_on_save = function(bufnr)
    -- Disable with a global or buffer-local variable
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
  end,
  -- If this is set, Conform will run the formatter asynchronously after save.
  -- It will pass the table to conform.format().
  -- This can also be a function that returns the table.
  format_after_save = function(bufnr)
    local ignore_filetypes = { "lua" }

    if vim.tbl_contains(ignore_filetypes, vim.bo[bufnr].filetype) then
      return { timeout_ms = 500, lsp_fallback = true }
    end

    local lines = vim.fn.system("git diff --unified=0 " .. vim.fn.bufname(bufnr)):gmatch "[^\n\r]+"
    local ranges = {}
    for line in lines do
      if line:find "^@@" then
        local line_nums = line:match "%+.- "
        if line_nums:find "," then
          local _, _, first, second = line_nums:find "(%d+),(%d+)"
          table.insert(ranges, {
            start = { tonumber(first), 0 },
            ["end"] = { tonumber(first) + tonumber(second), 0 },
          })
        else
          local first = tonumber(line_nums:match "%d+")
          table.insert(ranges, {
            start = { first, 0 },
            ["end"] = { first + 1, 0 },
          })
        end
      end
    end
    local format = require("conform").format
    for _, range in pairs(ranges) do
      format { range = range }
    end
  end,
  -- Set the log level. Use `:ConformInfo` to see the location of the log file.
  log_level = vim.log.levels.ERROR,
  -- Conform will notify you when a formatter errors
  notify_on_error = true,
  -- Custom formatters and changes to built-in formatters
  formatters = {},
}

return options
