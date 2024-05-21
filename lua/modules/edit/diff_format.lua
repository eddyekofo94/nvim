local diff_format = function()
  local buffer_readable = vim.fn.filereadable(vim.fn.bufname "%") > 0
  if not vim.fn.has "git" or not vim.g.conform_autoformat or not buffer_readable then
    return
  end
  local filetype = vim.api.nvim_buf_get_option(0, "filetype")
  local format = require("conform").format
  -- stylua range format mass up indent, so use fall format for now
  if filetype == "lua" then
    format {
      lsp_fallback = true,
      timeout_ms = 500,
    }
    return
  end
  local filename = vim.fn.expand "%:p"
  local lines = vim.fn.system("git diff --unified=0 " .. filename):gmatch "[^\n\r]+"
  local ranges = {}
  for line in lines do
    if line:find "^@@" then
      local line_nums = line:match "%+.- "
      if line_nums:find "," then
        local _, _, first, second = line_nums:find "(%d+),(%d+)"
        table.insert(ranges, {
          start = { tonumber(first), 0 },
          ["end"] = { tonumber(first) + tonumber(second) + 1, 0 },
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
  for _, range in pairs(ranges) do
    format {
      lsp_fallback = true,
      timeout_ms = 500,
      range = range,
    }
  end
end

vim.api.nvim_create_user_command("DiffFormat", diff_format, { desc = "Format changed lines" })

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = diff_format,
  desc = "Auto Format changed lines",
})
return {}
