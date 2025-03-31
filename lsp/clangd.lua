return {
  cmd = {
    "clangd",
    "--background-index",
    "--suggest-missing-includes",
    "--all-scopes-completion",
    "--completion-style=detailed",
    "--clang-tidy",
    "--cross-file-rename",
    "--fallback-style=Google",
    "--header-insertion=iwyu",
  },
  -- on_init = custom_init,
  -- on_attach = custom_attach,
  -- capabilities = updated_capabilities,
  init_options = {
    clangdFileStatus = true,
  },
  root_patterns = {
    ".clangd",
    ".clang-tidy",
    ".clang-format",
    "compile_commands.json",
    "compile_flags.txt",
    "configure.ac",
  },
}
