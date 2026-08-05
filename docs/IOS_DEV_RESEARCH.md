# iOS / Swift development in this Neovim config — research

Scope: how to get Swift/iOS editing, LSP, build/run/test, debugging, formatting,
linting, and syntax highlighting working from this Neovim config on macOS
(Darwin 25.5.0), given that the config currently has **zero** Swift/Xcode/
sourcekit references. Every non-trivial claim below is inline-cited to a
primary source (project README, docs/ folder, or source file) fetched directly
from the upstream repo — not a blog post. Anything I could not verify against
a primary source is marked `UNVERIFIED`.

---

## TL;DR — recommended stack

**Minimal path (fewest moving parts — LSP + format + lint only, build/run/debug stays in Xcode):**

1. `xcrun sourcekit-lsp` as the LSP (ships with Xcode / the Swift toolchain, no plugin needed) — configured natively via `after/lsp/sourcekit.lua`, the same convention this repo already uses for every other server.
2. `xcode-build-server` (Homebrew) run once per Xcode project (`xcode-build-server config -workspace ... -scheme ...`) so `sourcekit-lsp` gets real compiler flags for `.xcodeproj`/`.xcworkspace` targets. Not needed at all for pure SwiftPM packages.
3. `swift-format` (bundled in the toolchain since Swift 6 / Xcode 16, invoked as `swift format`) wired into `conform.nvim`, which is already this repo's formatter framework.
4. `swiftlint` (Homebrew) wired in via `mfussenegger/nvim-lint`'s built-in linter definition (simplest, exactly matches the primary-source example) — this repo doesn't currently have nvim-lint installed, so this is one new plugin.
5. Treesitter `swift` (+ `objc` for Objective-C interop) parsers added to the existing `ensure_installed` list.
6. Build, run on simulator/device, and debug from Xcode itself — nothing extra needed.

**Full path (everything wired up from inside Neovim: build/run/test/debug/simulator):**

Everything above, plus:

7. `wojciech-kulik/xcodebuild.nvim` — build, run, test, simulator control, test explorer, code coverage, all from Neovim, built on `xcodebuild`/`xcrun simctl`.
8. `codelldb` (via the plugin's DAP integration) wired into the `nvim-dap` this repo already has, using Xcode's own `LLDB.framework` as the backend (plain/bundled LLDB cannot read Swift debug info — see the Debugging section).
9. `xcbeautify` + `xcp` (XcodeProjectCLI) + `pymobiledevice3` as the external tool dependencies `xcodebuild.nvim` needs for log formatting, project-file manipulation, and physical-device debugging.

Either path leaves genuine Xcode-only tasks (Interface Builder, SwiftUI Canvas, provisioning UI, App Store Connect, Instruments) to Xcode — see "What still requires Xcode" below.

---

## Step 1 — this repo's actual conventions

Concrete facts read directly from `/Users/eddyekofo/.config/nvim`, not the Neovim version elsewhere on this machine.

- **Neovim version**: `/Users/eddyekofo/.config/nvim/nvim-version.txt` → `NVIM v0.13.0-dev-998+g4b69d3fd2d-Homebrew` — a Neovim **nightly build well past 0.11**, so every native `vim.lsp.config`/`vim.lsp.enable` API is available and is in fact the *only* LSP mechanism this repo uses.
- **Plugin manager**: Neovim's own built-in package manager, `vim.pack.add()` — documented in Neovim's own `runtime/doc/pack.txt` (`*vim.pack.add()*`, `*vim.pack.Spec*`) — not lazy.nvim, not packer. This repo wraps it with a thin lazy-loading layer in `/Users/eddyekofo/.config/nvim/lua/utils/pack.lua` (`M.add`, `M.register`, `M.lazy_load`), driven from `/Users/eddyekofo/.config/nvim/lua/core/pack.lua`, which collects plugin specs from `/Users/eddyekofo/.config/nvim/lua/pack/specs/start/*.lua` (eager) and `/Users/eddyekofo/.config/nvim/lua/pack/specs/opt/*.lua` (lazy, loaded on events/keys/cmds declared in each spec's `data` table).
- **LSP setup style**: **native `vim.lsp.config` / `vim.lsp.enable`, no nvim-lspconfig** (confirmed absent — `grep -rl nvim-lspconfig lua/` returns nothing). `/Users/eddyekofo/.config/nvim/lua/core/lsp.lua` sets a global default config with `vim.lsp.config("*", ...)`, then auto-enables **every** per-server config file it finds on the runtime `lsp/` path:
  ```lua
  for _, dir in ipairs(vim.api.nvim__get_runtime({ "lsp" }, true, {})) do
    for config_file in vim.fs.dir(dir) do
      vim.lsp.enable(vim.fn.fnamemodify(config_file, ":r"))
    end
  end
  ```
  Each server's config is its own file at `/Users/eddyekofo/.config/nvim/after/lsp/<name>.lua`, returning a plain `vim.lsp.Config` table — e.g. `after/lsp/clangd.lua`:
  ```lua
  ---@type lsp.config
  return {
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
    cmd = { "clangd" },
    root_markers = { { ".clangd", ".clang-tidy", ".clang-format" }, { "compile_commands.json", ... } },
  }
  ```
  This is exactly the file-per-server convention that `neovim/nvim-lspconfig` itself migrated to (see the nvim-lspconfig section below) — so a Swift config can be dropped in verbatim as `after/lsp/sourcekit.lua` with no new plugin dependency.
- **Formatter framework**: `stevearc/conform.nvim`, spec at `/Users/eddyekofo/.config/nvim/lua/pack/specs/opt/conform.lua`. `formatters_by_ft` is a plain Lua table (e.g. `lua = { "stylua" }`, `python = function(bufnr) ... end`), set up in that same file's `postload` callback along with `format_on_save`/`format_after_save`.
- **Linter framework**: **no `mfussenegger/nvim-lint`** in this repo. Instead, CLI linters that aren't real LSP servers are bridged into native LSP diagnostics through **`efm-langserver`**, one `after/lsp/<name>.lua` file per linter, e.g. `/Users/eddyekofo/.config/nvim/after/lsp/luacheck.lua`:
  ```lua
  ---@type lsp.config
  return {
    filetypes = { "lua" },
    cmd = { "efm-langserver" },
    requires = { "luacheck" },
    name = "luacheck",
    root_markers = { ".luacheckrc" },
    settings = {
      languages = {
        lua = { { lintSource = "luacheck", lintCommand = "luacheck --codes --no-color --quiet --filename ${INPUT} -", lintFormats = { "%.%#:%l:%c: (%t%n) %m" }, lintStdin = true } },
      },
    },
  }
  ```
  SwiftLint could in principle follow this same `efm-langserver` pattern, but I could not verify SwiftLint's exact `lintFormats` scanf string against a primary source (see the Formatting/Linting section for why `nvim-lint`'s built-in definition is the safer recommendation instead).
- **DAP setup**: `mfussenegger/nvim-dap` + `rcarriga/nvim-dap-ui`, specs at `/Users/eddyekofo/.config/nvim/lua/pack/specs/opt/nvim-dap.lua` and `.../nvim-dap-ui.lua`. Per-filetype adapter/config definitions live in `/Users/eddyekofo/.config/nvim/lua/pack/res/nvim-dap/dap/<ft>.lua` and are lazy-registered via `require("utils.load").ft_auto_load_once("pack.res.nvim-dap.dap", ...)`. **This repo already debugs C/C++ with `codelldb`** — `/Users/eddyekofo/.config/nvim/lua/pack/res/nvim-dap/dap/cpp.lua`:
  ```lua
  M.adapter = {
    type = "server", port = "${port}",
    executable = { command = vim.fn.exepath("codelldb"), args = { "--port", "${port}" } },
  }
  M.config = { { type = "codelldb", name = "Launch file", request = "launch", cwd = "${workspaceFolder}", program = utils.dap.get_prog(cache), args = utils.dap.get_args(cache) } }
  ```
  This is the exact same adapter Swift debugging needs — a `dap/swift.lua` (or having `xcodebuild.nvim` register it) is a natural drop-in.
- **Treesitter**: `/Users/eddyekofo/.config/nvim/lua/pack/specs/opt/nvim-treesitter.lua` installs `nvim-treesitter/nvim-treesitter` (`main` branch) and calls `require("nvim-treesitter.install").install(ensure_installed)` in `postload`, where `ensure_installed` is currently `{ "javascript", "markdown", ..., "cpp", "python", "java", ... }` (no Swift/Objective-C yet). Buffer-level start/stop/folding logic lives in `/Users/eddyekofo/.config/nvim/lua/core/treesitter.lua` and is filetype-generic, so it needs no changes — only the `ensure_installed` list.

---

## Concrete install/config — file by file

### 1. `after/lsp/sourcekit.lua` (new file)

`sourcekit-lsp` ships in both the Swift toolchain and Xcode and is invoked via `xcrun sourcekit-lsp` or `xcrun --find sourcekit-lsp` ([swiftlang/sourcekit-lsp README](https://github.com/swiftlang/sourcekit-lsp/blob/main/README.md)):

> "SourceKit-LSP is included in the Swift toolchains available on swift.org and is bundled with Xcode." — [sourcekit-lsp README](https://github.com/swiftlang/sourcekit-lsp/blob/main/README.md)

The exact config to drop in matches `neovim/nvim-lspconfig`'s own current `lsp/sourcekit.lua` (fetched from the repo directly — this is the modern, Neovim-0.11-native format nvim-lspconfig ships; see the nvim-lspconfig section below for why the old `lua/lspconfig/configs/sourcekit.lua` is deprecated):

```lua
-- after/lsp/sourcekit.lua
---@type lsp.config
return {
  cmd = { "sourcekit-lsp" }, -- or: { vim.trim(vim.fn.system("xcrun --find sourcekit-lsp")) }
  filetypes = { "swift", "objc", "objcpp", "c", "cpp" },
  root_dir = function(bufnr, on_dir)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local util = require("lspconfig.util") -- or reimplement root_pattern locally to avoid the dependency
    on_dir(
      util.root_pattern("buildServer.json", ".bsp")(filename)
        or util.root_pattern("*.xcodeproj", "*.xcworkspace")(filename)
        or util.root_pattern("compile_commands.json", "Package.swift")(filename)
        or vim.fs.dirname(vim.fs.find(".git", { path = filename, upward = true })[1])
    )
  end,
  get_language_id = function(_, ftype)
    local t = { objc = "objective-c", objcpp = "objective-cpp" }
    return t[ftype] or ftype
  end,
}
```
Source verified verbatim from [`neovim/nvim-lspconfig` `lsp/sourcekit.lua`](https://github.com/neovim/nvim-lspconfig/blob/master/lsp/sourcekit.lua). Since this repo has no nvim-lspconfig dependency, either vendor a small local `root_pattern` helper or accept the one dependency on `lspconfig.util` (nvim-lspconfig ships that module standalone even if you never call `require('lspconfig').setup()`). No `vim.lsp.enable("sourcekit")` call is needed in this file — `core/lsp.lua`'s runtime-path scan already enables every file it finds under `after/lsp/`.

### 2. `xcode-build-server config` (one-time per Xcode project, not a repo file)

For `.xcodeproj`/`.xcworkspace` projects, `sourcekit-lsp` has no compiler-flag source on its own — `xcode-build-server` supplies one via the Build Server Protocol:

> "Apple's sourcekit-lsp doesn't support xcode project. ... This repo aims to integrate xcode with sourcekit-lsp ... so I can develop iOS with my favorite editor." — [SolaWing/xcode-build-server README](https://github.com/SolaWing/xcode-build-server/blob/master/Readme.md)

Install and run once per project root:
```bash
brew install xcode-build-server
xcode-build-server config -workspace MyApp.xcworkspace -scheme MyApp
# or: xcode-build-server config -project MyApp.xcodeproj -scheme MyApp
```
This creates `buildServer.json` (`kind: xcode`), which `xcode-build-server` uses to watch the newest Xcode/`xcodebuild` build log for compiler flags — [README, "Bind to Xcode"](https://github.com/SolaWing/xcode-build-server/blob/master/Readme.md). Not needed for pure SwiftPM packages, since `sourcekit-lsp` reads `Package.swift` directly ([sourcekit-lsp README](https://github.com/swiftlang/sourcekit-lsp/blob/main/README.md)).

### 3. `after/lsp/swiftlint.lua` — `UNVERIFIED`, use `nvim-lint` instead (see below)

### 4. `lua/pack/specs/opt/conform.lua` (edit existing file)

`conform.nvim` already ships a built-in `swift_format` formatter definition (`lua/conform/formatters/swift_format.lua` in [stevearc/conform.nvim](https://github.com/stevearc/conform.nvim), confirmed present in the repo tree). Add to the existing `formatters_by_ft` table and `ft` list in `/Users/eddyekofo/.config/nvim/lua/pack/specs/opt/conform.lua`:
```lua
data = {
  ft = { "lua", "go", "json", "yaml", "javascript", "python", "sh", "zsh", "fish", "swift" },
  postload = function()
    require("conform").setup({
      formatters_by_ft = {
        -- ...existing entries...
        swift = { "swift_format" }, -- Apple's swift-format, bundled with Swift 6 / Xcode 16+
      },
    })
  end,
}
```
`swift-format` "provides the formatting technology for SourceKit-LSP" and, "Swift 6 (included with Xcode 16) and above include swift-format in the toolchain. You can run swift-format from anywhere on the system using `swift format`" — [swiftlang/swift-format README](https://github.com/swiftlang/swift-format/blob/main/README.md). `conform.nvim`'s `swift_format` formatter shells out to the `swift-format` binary; if only `swift format` (subcommand) is on PATH, point `conform`'s formatter `command` override at `xcrun --find swift-format` or `swift`, since I did not verify conform's built-in definition auto-detects the `swift format` subcommand form — `UNVERIFIED: did not read conform.nvim's swift_format.lua source to confirm which invocation form it defaults to`.

### 5. New plugin spec: `lua/pack/specs/opt/nvim-lint.lua` (new file, for SwiftLint)

The xcodebuild.nvim project's own wiki gives this exact config for integrating SwiftLint via `mfussenegger/nvim-lint` ([xcodebuild.nvim wiki, "Neovim Configuration"](https://github.com/wojciech-kulik/xcodebuild.nvim/wiki/Neovim-Configuration)), adapted to this repo's spec-file convention:
```lua
---@type pack.spec
return {
  src = "https://github.com/mfussenegger/nvim-lint",
  data = {
    events = { "BufReadPre", "BufNewFile" },
    postload = function()
      local lint = require("lint")
      lint.linters_by_ft = { swift = { "swiftlint" } }
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("lint.swift", { clear = true }),
        callback = function() require("lint").try_lint() end,
      })
    end,
  },
}
```
`nvim-lint` ships its own `swiftlint` linter definition already tuned to SwiftLint's `xcode` reporter output (`cmd = "swiftlint"`, pattern `"[^:]+:(%d+):(%d+): (%w+): (.+)"`) — confirmed by reading [`mfussenegger/nvim-lint`'s `lua/lint/linters/swiftlint.lua`](https://github.com/mfussenegger/nvim-lint/blob/master/lua/lint/linters/swiftlint.lua) directly, so no regex needs to be hand-written. Install SwiftLint with `brew install swiftlint` — [realm/SwiftLint README, "Homebrew"](https://github.com/realm/SwiftLint#homebrew). This is the one place the "full path" setup adds a genuinely new plugin family to the repo (adopting `efm-langserver` for SwiftLint instead was considered, matching the repo's existing linter convention, but I could not confirm SwiftLint's exact `lintFormats` scanf pattern from a primary source, so it is left as `UNVERIFIED` rather than guessed).

### 6. `lua/pack/specs/opt/nvim-treesitter.lua` (edit existing file)

Add `"swift"` and `"objc"` to the existing `ensure_installed` list:
```lua
local ensure_installed = {
  "javascript", "markdown", "markdown_inline", "yaml", "go", "regex", "json",
  "bash", "query", "fish", "lua", "luadoc", "cpp", "dockerfile", "python",
  "java", "gitcommit", "git_rebase", "diff", "xml", "toml",
  "swift", "objc", -- new
}
```
Both parsers are registered upstream in `nvim-treesitter/nvim-treesitter`'s own parser list ([`lua/nvim-treesitter/parsers.lua`](https://github.com/nvim-treesitter/nvim-treesitter/blob/main/lua/nvim-treesitter/parsers.lua)):
- `swift` → [alex-pinkus/tree-sitter-swift](https://github.com/alex-pinkus/tree-sitter-swift) (tier 2, `generate = true`)
- `objc` → [tree-sitter-grammars/tree-sitter-objc](https://github.com/tree-sitter-grammars/tree-sitter-objc) (tier 2, depends on the `c` parser, already installed)

### 7. `lua/pack/res/nvim-dap/dap/swift.lua` (new file, for plain nvim-dap without xcodebuild.nvim)

Mirroring the existing `cpp.lua` pattern, but pointing `codelldb` at Xcode's own Swift-aware LLDB (see Debugging section for why):
```lua
local M = {}
local utils = require("utils")
local cache = utils.dap.new_cache()

M.adapter = {
  type = "server",
  port = "${port}",
  executable = {
    command = vim.fn.exepath("codelldb"),
    args = { "--port", "${port}", "--liblldb", "/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/LLDB" },
  },
}
M.config = {
  { type = "codelldb", name = "Launch app", request = "launch", cwd = "${workspaceFolder}",
    program = utils.dap.get_prog(cache), args = utils.dap.get_args(cache) },
}
return M
```
The `--liblldb` path is exactly the default `xcodebuild.nvim` uses for its own `codelldb` integration (see Debugging section for the source). This file is only needed if you go the "minimal/manual DAP" route; `xcodebuild.nvim`'s `lua/xcodebuild/integrations/dap.lua` supersedes it when that plugin is installed.

---

## Topic research (primary sources)

### sourcekit-lsp

- What it is: "an implementation of the Language Server Protocol (LSP) for Swift and C-based languages... built on top of sourcekitd and clangd... supports projects that use the Swift Package Manager and projects that generate a `compile_commands.json` file" — [README](https://github.com/swiftlang/sourcekit-lsp/blob/main/README.md).
- Distribution: bundled with both swift.org toolchains and Xcode; invoke via `xcrun sourcekit-lsp` or discover with `xcrun --find sourcekit-lsp` — [README](https://github.com/swiftlang/sourcekit-lsp/blob/main/README.md); [Editor Integration doc](https://github.com/swiftlang/sourcekit-lsp/blob/main/Documentation/Editor%20Integration.md) (BBEdit section documents the same `xcrun --find` discovery convention other clients use).
- Capabilities: code completion, jump-to-definition, cross-module/cross-language support via its index, and a rich set of refactoring **Code Actions** (string/number literal conversions, control-flow refactors, etc.), invoked in Neovim via `vim.lsp.buf.code_action()` — [Refactoring Actions doc](https://github.com/swiftlang/sourcekit-lsp/blob/main/Documentation/Refactoring%20Actions.md) (the doc names Neovim + nvim-lspconfig explicitly for this binding).
- Important limitation: "SourceKit-LSP does not update its global index in the background or build Swift modules in the background. Thus, a lot of cross-module or global functionality is limited if the project hasn't been built recently" unless background indexing is enabled — [README](https://github.com/swiftlang/sourcekit-lsp/blob/main/README.md); background indexing is on by default since Swift 6.1 toolchains, and "is only supported for SwiftPM projects" (not Xcode projects) — [Enable Experimental Background Indexing doc](https://github.com/swiftlang/sourcekit-lsp/blob/main/Documentation/Enable%20Experimental%20Background%20Indexing.md).
- Config file: `~/.sourcekit-lsp/config.json` (also per-workspace `.sourcekit-lsp/config.json`), schema documented in full — [Configuration File doc](https://github.com/swiftlang/sourcekit-lsp/blob/main/Documentation/Configuration%20File.md).

### xcode-build-server (the compile-database problem)

- Problem it solves: "Apple's sourcekit-lsp doesn't support xcode project. But I found it provides a build server protocol to integrate with other build system." — [README](https://github.com/SolaWing/xcode-build-server/blob/master/Readme.md).
- Install: `brew install xcode-build-server`, or clone + symlink, or MacPorts — [README, "Install"](https://github.com/SolaWing/xcode-build-server/blob/master/Readme.md).
- Usage: `xcode-build-server config -workspace *.xcworkspace -scheme <X>` (or `-project`) generates/updates `buildServer.json` with `kind: xcode`, which tells the tool to watch the newest Xcode build log for compiler flags; rebuilding in Xcode refreshes the flags — [README, "Bind to Xcode"](https://github.com/SolaWing/xcode-build-server/blob/master/Readme.md). A "Manual Parse Xcodebuild log" mode also exists for non-Xcode-driven builds (`xcode-build-server parse`) — same README.
- Requires Python 3.9 (already present on recent macOS) — [README, "Install"](https://github.com/SolaWing/xcode-build-server/blob/master/Readme.md).

### nvim-lspconfig's sourcekit config (and why this repo doesn't need the plugin)

Fetched directly from `neovim/nvim-lspconfig`, which now maintains **two** copies:
- `lsp/sourcekit.lua` — the current, Neovim-0.11+-native format, directly `require`-able by `vim.lsp.enable('sourcekit')` without ever calling `require('lspconfig').setup()`: `cmd = { 'sourcekit-lsp' }`, `filetypes = { 'swift', 'objc', 'objcpp', 'c', 'cpp' }`, `root_dir` tries `buildServer.json`/`.bsp`, then `*.xcodeproj`/`*.xcworkspace`, then `compile_commands.json`/`Package.swift`, then falls back to the nearest `.git` — [`neovim/nvim-lspconfig/lsp/sourcekit.lua`](https://github.com/neovim/nvim-lspconfig/blob/master/lsp/sourcekit.lua).
- `lua/lspconfig/configs/sourcekit.lua` — the **old** format, explicitly marked in-source: *"This config is DEPRECATED. Use the configs in `lsp/` instead (requires Nvim 0.11). ALL configs in `lua/lspconfig/configs/` will be DELETED. They exist only to support Nvim 0.10 or older."* — [`neovim/nvim-lspconfig/lua/lspconfig/configs/sourcekit.lua`](https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/sourcekit.lua).

Since this repo runs Neovim 0.13-dev and already reads every `after/lsp/<name>.lua` file itself, the recommendation is to copy the content of nvim-lspconfig's `lsp/sourcekit.lua` into this repo's own `after/lsp/sourcekit.lua` rather than adding nvim-lspconfig as a dependency at all — it is literally the same file format this repo's `core/lsp.lua` already consumes.

### xcodebuild.nvim

- Purpose: "designed to let you migrate your app development from Xcode to Neovim... building, debugging, and testing" — [README](https://github.com/wojciech-kulik/xcodebuild.nvim/blob/main/README.md).
- Features (from the README's feature list, and expanded in the wiki's Features page): iOS/iPadOS/watchOS/tvOS/visionOS/macOS support, SwiftPM build/test, Project Manager (edit target membership without Xcode), Assets Manager, Test Explorer, build/run/debug/test on simulators and physical devices via `xcodebuild`/`xcrun simctl`, SwiftUI/UIKit/AppKit previews, code coverage, `nvim-dap`/`nvim-dap-ui` integration, lualine integration, Quick/Swift Testing/snapshot-testing integration — [README](https://github.com/wojciech-kulik/xcodebuild.nvim/blob/main/README.md), [wiki Features page](https://github.com/wojciech-kulik/xcodebuild.nvim/wiki/Features).
- Requirements (from the wiki's own install page): Neovim 0.9.5+; a picker (telescope/fzf-lua/snacks); `nui.nvim`; optionally `nvim-tree`/`neo-tree`/`oil.nvim`; `nvim-dap`+`nvim-dap-ui` for debugging; `nvim-treesitter` + Swift parser (for Quick framework test results); external tools `xcbeautify`, `XcodeProjectCLI (xcp)`, `pymobiledevice3` (physical-device / pre-iOS-17 debugging), `jq`, `xcode-build-server`, `ripgrep`, `coreutils`; and Xcode itself (tested with Xcode 15+) — [wiki Home/Requirements page](https://github.com/wojciech-kulik/xcodebuild.nvim/wiki/Home). Quick-install: `brew install xcp xcode-build-server xcbeautify pipx rg jq coreutils && pipx install pymobiledevice3`, or `make install` from the plugin's own directory — same page.
- Doc location: the "docs/" content lives in the project's **GitHub Wiki** (a separate git repo, `xcodebuild.nvim.wiki`), not a `docs/` folder in the main repo — cloned and read directly for this research (`Home.md`, `Features.md`, `Integrations.md`, `Neovim-Configuration.md`).

### Debugging: nvim-dap + codelldb

- Why plain LLDB/`lldb-vscode` struggles with Swift: "The default LLDB backend bundled with CodeLLDB supports C, C++, Rust, as well as many other languages whose debug info is compatible with C++, however this list does not include Swift. It appears that Swift has diverged far enough from C++ that LLDB cannot interpret its debug info without a special Swift plugin." The fix is to point CodeLLDB at "an alternate debugger backend, namely, the one provided with the Swift toolchain" (on macOS, the system `lldb`) — [vadimcn/codelldb wiki, "Swift" page](https://github.com/vadimcn/codelldb/wiki/Swift).
- codelldb itself lists Swift as a supported (if secondary) language, with its own wiki page dedicated to the caveat above: "usable with most other compiled languages whose compiler generates compatible debugging information, such as ... Swift" — [vadimcn/codelldb README](https://github.com/vadimcn/codelldb/blob/master/README.md).
- `xcodebuild.nvim` bakes this exact workaround into its `codelldb` DAP integration module (`lua/xcodebuild/integrations/codelldb.lua`): the adapter is launched as `codelldb --port <port> --liblldb <lldb_lib_path>`, and the default `lldb_lib_path` in `lua/xcodebuild/core/config.lua` is `/Applications/Xcode.app/Contents/SharedFrameworks/LLDB.framework/Versions/A/LLDB` — i.e. Xcode's own bundled, Swift-aware LLDB, not codelldb's built-in one — confirmed by reading both files directly from [`wojciech-kulik/xcodebuild.nvim`](https://github.com/wojciech-kulik/xcodebuild.nvim/blob/main/lua/xcodebuild/integrations/codelldb.lua). The plugin's wiki also documents wiring this into `nvim-dap` directly (`require("xcodebuild.integrations.dap").setup()`, plus keymaps for build & debug, debug tests, toggle breakpoint, etc.) — [wiki Integrations page, "Debugger"](https://github.com/wojciech-kulik/xcodebuild.nvim/wiki/Integrations).
- `xcodebuild.nvim` also ships a `dap.lua` integration module (confirmed present at `lua/xcodebuild/integrations/dap.lua` in the repo tree) that wraps build+debug, debug-without-building, and debug-tests workflows around the codelldb adapter above.

### Formatting / linting

- **swift-format**: "provides the formatting technology for SourceKit-LSP." As of Swift 6 (bundled with Xcode 16+), it ships inside the toolchain and is invocable as `swift format` (a subcommand, space not dash); `xcrun --find swift-format` locates the toolchain copy. It can also be installed separately via Homebrew (`brew install swift-format`) or built from source, and older Xcode/Swift versions must match specific `swift-format` release branches (table in the README) — [swiftlang/swift-format README](https://github.com/swiftlang/swift-format/blob/main/README.md). It integrates naturally with `conform.nvim` (this repo's formatter framework) since conform already ships a built-in `swift_format` formatter definition (confirmed present at `lua/conform/formatters/swift_format.lua` in [stevearc/conform.nvim](https://github.com/stevearc/conform.nvim)); it does not need `nvim-lint` since it's a formatter, not a linter.
- **SwiftLint**: "A tool to enforce Swift style and conventions... predominantly based on SwiftSyntax. Some rules still hook into Clang and SourceKit" — [realm/SwiftLint README](https://github.com/realm/SwiftLint/blob/main/README.md). Install via Homebrew (`brew install swiftlint`), SwiftPM build-tool/command plugin, CocoaPods, Mint, or Bazel — same README, "Installation". Default output reporter is `xcode`-format compiler-style diagnostics (`reporter: "xcode"` in the default `.swiftlint.yml`) — same README, configuration section. Integration: `mfussenegger/nvim-lint` ships a ready-made `swiftlint` linter definition (`cmd = "swiftlint"`, args `lint --use-stdin` or `lint --force-exclude --config <path>` if a `.swiftlint.yml` is found, output parsed with pattern `"[^:]+:(%d+):(%d+): (%w+): (.+)"`) — confirmed by reading [`mfussenegger/nvim-lint`'s `lua/lint/linters/swiftlint.lua`](https://github.com/mfussenegger/nvim-lint/blob/master/lua/lint/linters/swiftlint.lua) directly. Wiring SwiftLint through this repo's existing `efm-langserver` convention instead (matching `luacheck.lua`/`hadolint.lua`) is possible in principle but its exact `lintFormats` scanf string is `UNVERIFIED: I did not find or test an efm-langserver lintFormats pattern for SwiftLint's xcode reporter against a primary source, so I did not fabricate one` — use the `nvim-lint` route above instead, since it's a byte-for-byte primary-sourced definition.

### Treesitter

- `nvim-treesitter/nvim-treesitter`'s own parser registry (`lua/nvim-treesitter/parsers.lua`) lists:
  - `swift` → upstream grammar [alex-pinkus/tree-sitter-swift](https://github.com/alex-pinkus/tree-sitter-swift), tier 2, `generate = true` (grammar is generated from source at install time) — [`nvim-treesitter/nvim-treesitter` `parsers.lua`](https://github.com/nvim-treesitter/nvim-treesitter/blob/main/lua/nvim-treesitter/parsers.lua).
  - `objc` → [tree-sitter-grammars/tree-sitter-objc](https://github.com/tree-sitter-grammars/tree-sitter-objc), tier 2, depends on the `c` parser — same file. This repo already installs `cpp`, so `c` is very likely already pulled in transitively, but `objc` should be added explicitly to `ensure_installed` regardless.
- `alex-pinkus/tree-sitter-swift` is an actively maintained, independently distributed grammar (published to crates.io and npm) — [tree-sitter-swift README](https://github.com/alex-pinkus/tree-sitter-swift/blob/main/README.md).

### Simulator + preview workflow — honest limits

**Genuinely possible from Neovim / the terminal:**
- Booting/listing simulators and installing/launching apps via `xcrun simctl` directly, or through `xcodebuild.nvim`'s simulator-control actions, which are "Built using official command line tools like `xcodebuild` and `xcrun simctl`" — [xcodebuild.nvim README](https://github.com/wojciech-kulik/xcodebuild.nvim/blob/main/README.md).
- Streaming simulator app logs into `nvim-dap-ui`'s console window without attaching a debugger (`:lua require("dapui").toggle()`, then run the app) — [xcodebuild.nvim wiki, Integrations, "Application Logs"](https://github.com/wojciech-kulik/xcodebuild.nvim/wiki/Integrations); or via a plain log file the plugin writes at `.nvim/xcodebuild/app_logs.log` (`tail -f` it) — same page.
- Building, running, and debugging on **physical devices**, though iOS 17+ requires a secure tunnel via `pymobiledevice3` that needs `sudo` for two specific operations, and devices on iOS <17 need `pymobiledevice3` for install/launch at all — [xcodebuild.nvim wiki, Integrations, "Debugging On iOS 17+"](https://github.com/wojciech-kulik/xcodebuild.nvim/wiki/Integrations) and the wiki's own **Availability table** (Features page), which is explicit that some device/network combinations for install, debug, and debug-tests are simply ❌ not supported, not just harder — [wiki Features page, "Availability"](https://github.com/wojciech-kulik/xcodebuild.nvim/wiki/Features).
- SwiftUI/UIKit/AppKit **previews** rendered as images inside Neovim — but this requires installing a separate Swift Package (`xcodebuild-nvim-preview`) into your app, adding `snacks.nvim` for image rendering, and every preview request triggers a real build+run of the app to generate the image (not a live canvas) — [xcodebuild.nvim wiki, Integrations, "Previews"](https://github.com/wojciech-kulik/xcodebuild.nvim/wiki/Integrations).

**Still requires Xcode itself:**
- Interface Builder / storyboards (no terminal/LSP equivalent exists in any source consulted).
- SwiftUI **live** Previews/canvas with hot-reloading-as-you-type — `xcodebuild.nvim`'s preview feature is a build-and-screenshot mechanism triggered on demand (optionally with a "hot reload" mode via an additional `HotSwiftUI` package integration), not Xcode's live canvas — [wiki Integrations, "Previews"](https://github.com/wojciech-kulik/xcodebuild.nvim/wiki/Integrations). `UNVERIFIED: no primary source consulted claims feature parity with Xcode's canvas` — treat it as a materially different, slower mechanism.
- Provisioning-profile / signing UI, and App Store Connect submission — not mentioned as a capability by `xcodebuild.nvim`'s README, Features, or Integrations pages; `xcodebuild`/`xcrun` CLI can drive signing if profiles already exist and are correctly set up, but the interactive profile-management UI itself is Xcode/developer.apple.com only. `UNVERIFIED: no primary source consulted describes a CLI path around Xcode's own signing UI for first-time profile setup.`
- Instruments profiling — not mentioned in any primary source consulted for this doc; no CLI-from-Neovim equivalent is claimed anywhere in `xcodebuild.nvim`'s docs.

### Alternatives worth naming

- **Plain Neovim + Xcode side-by-side**: edit in Neovim (with just `sourcekit-lsp` + `xcode-build-server` for LSP-only intelligence), keep building/running/debugging/simulator work in Xcode. Zero new Neovim plugins beyond the LSP config itself.
- **`xcode-build-server` alone (LSP only, no `xcodebuild.nvim`)**: gets full code intelligence (completion, diagnostics, refactoring, jump-to-definition) for Xcode-project Swift/ObjC files without touching build/run/debug workflows at all — this is the "minimal path" above.
- **Full `xcodebuild.nvim`**: everything wired up, at the cost of several external tool dependencies (`xcbeautify`, `xcp`, `pymobiledevice3`, `codelldb`) and picker/UI plugin dependencies (`nui.nvim`, a fuzzy picker, optionally `nvim-tree`/`oil.nvim`) — [wiki Home page, Requirements](https://github.com/wojciech-kulik/xcodebuild.nvim/wiki/Home).
- **Tuist**: "a virtual platform team for Swift app devs"; its "Generated projects" feature is "a solution for more accessible and easier-to-manage Xcode projects" — i.e. define the project in code/config and generate `.xcodeproj`/`.xcworkspace` rather than hand-editing them, reducing merge-conflict pain — [tuist/tuist README](https://github.com/tuist/tuist/blob/main/README.md).
- **XcodeGen**: "a command line tool written in Swift that generates your Xcode project using your folder structure and a project spec" (YAML/JSON) — same category as Tuist, simpler/more focused — [yonaskolb/XcodeGen README](https://github.com/yonaskolb/XcodeGen/blob/master/README.md).
- **Pure SwiftPM projects (no `.xcodeproj` at all)**: sidestep the entire compile-database problem — `sourcekit-lsp` reads `Package.swift` natively, so `xcode-build-server` is never needed; `xcodebuild.nvim` also explicitly supports "Swift Packages (building & testing)" as a first-class case, separate from its Xcode-project support — [xcodebuild.nvim README](https://github.com/wojciech-kulik/xcodebuild.nvim/blob/main/README.md), [wiki Features page, "Swift Package Development"](https://github.com/wojciech-kulik/xcodebuild.nvim/wiki/Features) (note: only library targets are supported this way — "executable packages are not supported").

---

## Sources

| Claim | Source |
|---|---|
| sourcekit-lsp identity, SwiftPM/compile_commands.json support, bundling | https://github.com/swiftlang/sourcekit-lsp/blob/main/README.md |
| `xcrun --find` discovery convention used by editors | https://github.com/swiftlang/sourcekit-lsp/blob/main/Documentation/Editor%20Integration.md |
| Refactoring / Code Actions, Neovim `vim.lsp.buf.code_action()` binding | https://github.com/swiftlang/sourcekit-lsp/blob/main/Documentation/Refactoring%20Actions.md |
| Background indexing default-on since 6.1, SwiftPM-only limitation | https://github.com/swiftlang/sourcekit-lsp/blob/main/Documentation/Enable%20Experimental%20Background%20Indexing.md |
| `config.json` schema and lookup paths | https://github.com/swiftlang/sourcekit-lsp/blob/main/Documentation/Configuration%20File.md |
| xcode-build-server purpose, install, `config`/`parse` usage | https://github.com/SolaWing/xcode-build-server/blob/master/Readme.md |
| nvim-lspconfig current native sourcekit config | https://github.com/neovim/nvim-lspconfig/blob/master/lsp/sourcekit.lua |
| nvim-lspconfig old config explicitly marked deprecated | https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/configs/sourcekit.lua |
| xcodebuild.nvim purpose and feature list | https://github.com/wojciech-kulik/xcodebuild.nvim/blob/main/README.md |
| xcodebuild.nvim requirements, install, external tools | https://github.com/wojciech-kulik/xcodebuild.nvim/wiki/Home |
| xcodebuild.nvim LSP/SwiftFormat/SwiftLint config examples | https://github.com/wojciech-kulik/xcodebuild.nvim/wiki/Neovim-Configuration |
| xcodebuild.nvim debugger, previews, app-logs integrations | https://github.com/wojciech-kulik/xcodebuild.nvim/wiki/Integrations |
| xcodebuild.nvim availability table (device/simulator honest limits) | https://github.com/wojciech-kulik/xcodebuild.nvim/wiki/Features |
| xcodebuild.nvim codelldb integration source (`--liblldb` default path) | https://github.com/wojciech-kulik/xcodebuild.nvim/blob/main/lua/xcodebuild/integrations/codelldb.lua |
| Why plain LLDB/CodeLLDB backend can't read Swift debug info | https://github.com/vadimcn/codelldb/wiki/Swift |
| codelldb supported languages, incl. Swift | https://github.com/vadimcn/codelldb/blob/master/README.md |
| swift-format bundled with Swift 6/Xcode 16, `swift format` subcommand | https://github.com/swiftlang/swift-format/blob/main/README.md |
| SwiftLint identity, install methods, default `xcode` reporter | https://github.com/realm/SwiftLint/blob/main/README.md |
| nvim-lint's built-in SwiftLint linter definition | https://github.com/mfussenegger/nvim-lint/blob/master/lua/lint/linters/swiftlint.lua |
| nvim-treesitter parser registry (`swift`, `objc` entries) | https://github.com/nvim-treesitter/nvim-treesitter/blob/main/lua/nvim-treesitter/parsers.lua |
| tree-sitter-swift grammar identity | https://github.com/alex-pinkus/tree-sitter-swift/blob/main/README.md |
| Tuist generated-projects pitch | https://github.com/tuist/tuist/blob/main/README.md |
| XcodeGen pitch and spec format | https://github.com/yonaskolb/XcodeGen/blob/master/README.md |
| `vim.pack.add()` is Neovim's own native package manager | https://github.com/neovim/neovim/blob/master/runtime/doc/pack.txt |
| This repo's Neovim version | `/Users/eddyekofo/.config/nvim/nvim-version.txt` |
| This repo's native LSP enable-all-servers mechanism | `/Users/eddyekofo/.config/nvim/lua/core/lsp.lua` |
| This repo's per-server LSP config convention | `/Users/eddyekofo/.config/nvim/after/lsp/clangd.lua`, `rust-analyzer.lua`, `gopls.lua` |
| This repo's efm-langserver-as-linter convention | `/Users/eddyekofo/.config/nvim/after/lsp/luacheck.lua`, `hadolint.lua` |
| This repo's conform.nvim formatter config | `/Users/eddyekofo/.config/nvim/lua/pack/specs/opt/conform.lua` |
| This repo's existing codelldb-based C/C++ DAP config | `/Users/eddyekofo/.config/nvim/lua/pack/res/nvim-dap/dap/cpp.lua` |
| This repo's treesitter `ensure_installed` list | `/Users/eddyekofo/.config/nvim/lua/pack/specs/opt/nvim-treesitter.lua` |
