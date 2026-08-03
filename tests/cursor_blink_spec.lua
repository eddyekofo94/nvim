describe("cursor blinking", function()
  it(
    "applies blink timing to every mode without replacing mode shapes",
    function()
      local guicursor = vim.opt.guicursor:get()

      assert.is_true(
        vim.tbl_contains(guicursor, "a:blinkwait500-blinkon400-blinkoff300")
      )
      assert.is_true(
        vim.tbl_contains(
          guicursor,
          "i-ci:ver30-Cursor-blinkwait500-blinkon400-blinkoff300"
        )
      )
      assert.is_true(vim.tbl_contains(guicursor, "n-v:block-Cursor/lCursor"))
      assert.is_true(vim.tbl_contains(guicursor, "o:hor50-Cursor/lCursor"))
      assert.is_true(vim.tbl_contains(guicursor, "r-cr:hor20-Cursor/lCursor"))
    end
  )
end)
