-- Apple's Swift language server.
--
-- Ships inside the Xcode toolchain rather than on `$PATH`, so it is invoked
-- through `xcrun`, the documented entry point:
-- https://github.com/swiftlang/sourcekit-lsp
--
-- Compiler flags come from `Package.swift` for SwiftPM packages. Plain
-- `.xcodeproj`/`.xcworkspace` projects need a build server database first:
--   brew install xcode-build-server
--   xcode-build-server config -workspace MyApp.xcworkspace -scheme MyApp
-- which writes the `buildServer.json` matched below.
--
-- Objective-C/C/C++ are intentionally left to `clangd` (see `clangd.lua`) so
-- the two servers do not both attach to the same buffers.

---@type lsp.config
return {
  name = "sourcekit",
  filetypes = { "swift" },
  cmd = { "xcrun", "sourcekit-lsp" },
  root_markers = {
    -- Build server database, written by `xcode-build-server config`
    { "buildServer.json", ".bsp" },
    -- Native build descriptions sourcekit-lsp reads on its own
    { "Package.swift", "compile_commands.json" },
    -- Bare Xcode project without a build server; `vim.fs.root()` does not
    -- expand globs, so match the extension with a predicate instead
    function(name)
      return name:match("%.xcworkspace$") ~= nil
        or name:match("%.xcodeproj$") ~= nil
    end,
  },
}
