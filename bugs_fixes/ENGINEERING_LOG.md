# Engineering log

## 2026-09-04 - Neovim 0.13 upgrade, phase 1 (config-owned deprecations)

Branch `chore/nvim-0.13-upgrade`, phase 1 of `docs/NVIM_0.13_UPGRADE_PLAN.md`.
No plugin versions changed.

- Replaced the removed `BufModifiedSet` event with `OptionSet` matching the
  `modified` option in `plugin/intro.lua`. This was a hard `Invalid 'event'`
  error on every interactive no-argument start. Applied the same swap in the
  disabled `lua/plugin/winbar/` fork through a new `update_events.buf_options`
  list, so the winbar keeps a filtered `OptionSet` autocmd instead of an
  unfiltered one on every option write.
- Renamed the `vim.diagnostic.config()` jump field `callback` to the documented
  `on_jump(diagnostic, bufnr)`. `]d` / `[d` never opened the float before this.
- `vim.F.npcall` -> `vim.npcall` in 8 files (deprecated 0.13, removed 0.15).
- `vim.highlight.on_yank` -> `vim.hl.hl_op` (deprecated, removal in 0.14).
- `vim.loop.os_uname` -> `vim.uv.os_uname` in `after/lsp/eslint.lua`.
- Rebuilt the `:Lsp` subcommands on the 0.13 capability API:
  `semantic_tokens.start/stop` and `codelens.clear/display/save/on_codelens/
  refresh` are gone, replaced by `*_enable`, `*_disable`, `*_toggle`, and
  `*_is_enabled` over `enable(bool, filter)`. `codelens_get` now takes a filter
  table and prints its result.
- Deleted the `vim.treesitter.get_parser` monkey patch in `lua/core/autocmds.lua`
  that called the private `vim.treesitter._create_parser`. Big-file protection
  still comes from the existing `vim.treesitter.stop()` autocmd and the
  `foldexpr` guard, which were kept.
- Fixed the two callers that relied on `get_parser` throwing. On 0.13 it returns
  `nil, err`, so a bare `pcall` always succeeded: `lua/plugin/statusline.lua`
  showed the ` TS` indicator for every buffer and
  `lua/pack/specs/start/dropbar.nvim.lua` attached Dropbar to every buffer.
  Both now test the returned parser, and the statusline also skips big files.
- Added two checks to `tools/verify.sh`: a UI-less probe that sources
  `plugin/intro.lua` with `vim.g.has_ui` stubbed (the existing headless runs
  never reached its autocmds), and a `:checkhealth vim.deprecated` gate that
  fails on any traceback pointing back into this repository.

Automated status: `tools/verify.sh` passes. `:checkhealth vim.deprecated`
reports no deprecated functions. The intro probe was negative-tested by
re-adding `BufModifiedSet` and confirming it fails.

Known baseline, unchanged: whole-repository `make format-check` fails on
pre-existing drift in `lua/plugin/agent-prompt.lua`. `stylua --check` is clean
on every file this phase touched.

## 2026-07-15 - Neovim HEAD and plugin compatibility refresh

- Updated Neovim from `v0.13.0-dev-3729+g0bb2f5cc08` to
  `v0.13.0-dev-998+g4b69d3fd2d`.
- Updated all 86 previously registered plugins and added `blink.lib`, required
  by Blink Completion v2.
- Fixed `vim.pack` updates failing when structured specs contain Lua callbacks;
  native specs now remain serialization-safe while callbacks stay private to
  the custom loader.
- Fixed legacy top-level structured spec fields so Dropbar's custom setup runs.
- Removed a Dropbar global override that replaced its callable winbar object.
- Guarded lazy-loader event replay against nested `FileType` re-entry exposed by
  Otter's embedded-language buffers.
- Replayed lazy-loaded commands with the exact Neovim API, fixing commands such
  as `:Mason` becoming ambiguous beside `:MasonInstall` on current HEAD.
- Migrated Blink's dependency and native-library build for v2.
- Kept the custom Smart Files producer out of fzf-lua's new nested multiprocess
  shell, preserving ordered recent-file deduplication and restoring its entries.
- Restored the Python provider and regenerated the Molten remote-plugin manifest.
- Repaired incomplete plugin worktrees left by the interrupted first update.
- Added `tools/verify.sh`, workflow status, and an interactive QA checklist.

Automated status: `tools/verify.sh` passes. An isolated real-TTY pass confirmed
the rendered Markdown UI, statusline/winbar, Dropbar and `<leader>ls`, Smart
Files (503 entries), F3/F5/F6 preview controls, Mason, Fugitive, and table-mode
command replay without runtime errors. The remaining subjective and
service-dependent checks are listed in `docs/MANUAL_QA.md`.

Known baseline: whole-repository `make format-check` and `make lint` fail on
pre-existing formatting drift and 30 warnings outside the compatibility files.

## 2026-07-15 - Stale Dropbar in app-launched Neovim

- Reproduced the reported `Invalid 'event': 'BufModifiedSet'` error with a
  clean environment that omitted shell-provided XDG variables.
- Found two independent Neovim data roots: the refreshed shell-visible store at
  `~/.config/.local/share/nvim` and a stale default store at
  `~/.local/share/nvim`. The latter contained Dropbar from October 2025 and
  x86_64 Treesitter parsers.
- Merged unique history, session, undo, and application state into the refreshed
  store, then linked the default path to that canonical store.
- Preserved the complete old store at
  `~/.local/share/nvim.legacy-20260715-0325` for rollback.
- Extended `tools/verify.sh` to require both launch environments to resolve to
  the same real data root and to run Dropbar plus a full startup without XDG
  variables.

Automated status: the exact Dropbar reproduction passes three consecutive runs,
clean-environment full startup passes, and `tools/verify.sh` covers the split
data-root regression.

## 2026-07-15 - Blink v2 completion initialization

- Reproduced Blink loading without a menu, keymaps, or candidates in a fresh
  real-TTY Lua buffer.
- Found that Blink v2 rejected the v1 mode-specific source shape
  `cmdline.sources = function() ... end`. The package loader swallowed that
  first setup error, leaving Blink's one-shot setup guard permanently
  half-initialized.
- Migrated command-line sources to the v2 nested `sources.default` schema and
  replaced the removed renderer `get_completion_type` API with Neovim's active
  command-line completion type.
- Made package-add failures visible instead of silently discarding postload
  errors.
- Converted Sidekick's lazy.nvim-only `VeryLazy` event into a real
  `User VeryLazy` event emitted after `UIEnter`.
- Extended `tools/verify.sh` to assert that Blink's trigger and source listeners
  are actually initialized, not merely that its native library exists.

Automated status: `tools/verify.sh` passes. Real-TTY checks returned 56
Insert-mode candidates, rendered the menu, installed `<C-Space>`, accepted
`completion_candidate` with `<C-n><CR>`, and rendered command-line path
completion without errors.

## 2026-07-15 - Smart Files cumulative grep transport

- Reproduced `converter` -> `Ctrl-G` -> `OVERRIDES` returning `0/0` even though
  `converter.py` contained matches.
- Forced ripgrep filenames for one-file xargs batches.
- Prevented fzf-lua from mistaking xargs' NUL-delimited input for
  NUL-delimited ripgrep output by quoting the `'-0'` flag.
- Added a regression test through the real fzf-lua libuv output transform, not
  only direct shell execution.

Automated status: all five Smart Files tests pass and `tools/verify.sh` passes.
Normal-session QA confirmed the exact grep result, toggle-back, `Ctrl-R`, and
F4/F5 preview behavior with empty `:messages` output.

## 2026-07-15 - Trigger-accurate lazy loading and Copilot lifecycle

- Reproduced `UIEnter` loading unrelated optional plugins because the custom
  loader treated any installed plugin containing `lua/` or `plugin/` as eager.
- Marked collected specs with their actual `start`/`opt` origin and removed the
  filesystem-content heuristic, so trigger-bearing opt plugins wait for their
  configured command, key, event, or explicit dependency. Intentionally
  non-lazy opt specs still load when the opt set is registered after startup.
- Removed Sidekick's Copilot dependency because Sidekick NES is disabled;
  Sidekick continues to load on `User VeryLazy` with all CLI mappings intact.
- Moved Copilot startup to `InsertEnter` and added `VimLeavePre` teardown plus a
  forced client stop, covering both active clients and scheduled-startup races.
- Added UIEnter and process-lifecycle regressions to `tools/verify.sh`.
- Fixed two command-line event precedence errors and one tmux floating-window
  precedence error, then removed the dead code exposed by the full lint pass.
- Aligned the repository with StyLua's documented two-space, parenthesized-call
  style and the preferred double-quote policy; whole-repository formatting and
  lint now pass.
- Restored Homebrew command discovery for GUI/clean-environment launches and
  made the verifier assert that `fzf` is available in that context.
- Deleted the tracked statusline backup and Python bytecode, ignored equivalent
  generated debris, and removed the inactive `data/lazy` and `data/packages`
  stores after a quarantine verification pass.
- Previewed 36 orphaned Copilot language servers (831.2 MiB RSS), terminated
  that exact PID set with `TERM`, and confirmed zero survivors.

Automated status: `tools/verify.sh`, full `make lint`, `make format-check`, clean
startup, and repeated Copilot process-lifecycle checks pass. Real-TTY QA showed
Copilot `Online` and attached with an inline suggestion and `<C-j>` mapping;
Sidekick's live 18-entry CLI selector opened normally. Every QA exit left zero
Copilot language-server orphans.

## 2026-09-04 - Neovim 0.13 upgrade phase 2: plugin and lockfile removals

- Deleted `nvim-treesitter-incremental-selection` (archived upstream) and
  `nvterm` (unmaintained; `lua/plugin/term.lua` already owns terminals).
- Gave Neovim's built-in |v_an| / |v_in| ownership of visual `an` / `in`, and
  moved mini.ai's next/last textobjects to `aN`/`iN`/`aL`/`iL` as
  |MiniAi-default-an-in| recommends, freeing 0.13's `al`/`il` as well.
- Kept the removed plugin's LSP preference in `lua/core/keymaps.lua`:
  `an`/`in` call `vim.lsp.buf.selection_range()` when a client advertises
  `textDocument/selectionRange` and fall back to the built-in maps otherwise.
- Fixed `utils.key.get()`, which only searched `nvim_get_keymap()` and so never
  found Neovim's own Visual+Select defaults. `key.amend()` silently replaced
  built-in maps instead of wrapping them; it now consults `maparg()` and
  `fallback_fn()` re-feeds the result of an `expr` mapping.
- Implemented `data.enabled` in `lua/utils/pack.lua`. Four specs
  (fluoride, nvterm, termite, themeswitcher) set `enabled = false` and loaded
  anyway; the plan's count of seven also listed noice, sidekick, and which-key,
  which only set `enabled` inside their own setup tables.
- Converted the five inert lazy.nvim `dependencies` lists to `deps` with full
  source URLs and dropped neogit's inert `branch`. lazydev's archived
  `Bilal2453/luvit-meta` dependency became Neovim's bundled
  `${3rd}/luv/library`.
- `:packdel`'d nine lockfile entries with no spec: the six known orphans
  (`lsp-timeout.nvim`, `mini.icons`, `nvim-lspconfig`, `smart-motion.nvim`,
  `snacks.nvim`, `volt`), plus `oil.nvim` (replaced by the `canola.nvim` fork,
  which ships the same `oil` module), `nvterm`, and
  `nvim-treesitter-incremental-selection`. Lockfile and store are both 78.
- Added `tools/check_pack_lock.lua` to `tools/verify.sh`, because `vim.pack`
  reinstalls every lockfile entry on its first call, so a spec-less entry
  otherwise returns after `:restart`.

Automated status: `tools/verify.sh` and `make lint` pass; `make format-check`
still reports the two pre-existing diffs in `lua/plugin/agent-prompt.lua` and
`tests/agent_prompt_spec.lua`, unchanged by this phase. Headless checks confirm
`an` expands and `in` shrinks the selection, `aN` is mini.ai's around-next,
themeswitcher and nvterm no longer load, and diffview still pulls plenary
through the converted `deps`. No real-TTY QA yet.

## 2026-09-04 - Neovim 0.13 upgrade phase 3: moved plugin repositories

Seven specs still pointed at repositories that had moved. Repointed in one
commit with `nvim-pack-lock.json`:

- `focus.nvim` `beauwilliams` -> `nvim-focus`.
- `mini.nvim` and `mini.ai` `echasnovski` -> `nvim-mini`.
- `nvim-web-devicons` `kyazdani42` -> `nvim-tree`, in the standalone spec and
  the five `deps` entries (`fzf-lua`, `oil`, `blink-cmp`, `nvim-dap-ui`,
  `triptych`); the plan listed four and missed `triptych.lua:9`.
- `nvim-colorizer.lua` `NvChad` -> `catgoose`.
- `mason.nvim` `williamboman` -> `mason-org`, in `mason.lua` and the
  `mason-tool-installer.nvim` dep entry.

Plan correction: `vim.pack` does **not** delete and re-clone when `src`
changes. `vim.pack.get()` reported every new URL and `:PackInstallAll` was a
no-op — the on-disk remotes and the lockfile kept the old owners, so a future
`vim.pack.update()` would have fetched from the moved repositories. The
re-clone has to be forced: `vim.pack.del()` the six directories, then
`:PackInstallAll`. Only `mason-tool-installer.nvim` needed no store change,
because just its dep entry moved.

Two revisions advanced with the move: `mini.nvim` `05a80b03` -> `9d01f392` and
`nvim-web-devicons` `0ca28b61` -> `5f032a85`. The other four re-cloned at the
same revision.

Automated status: `tools/verify.sh` passes, including `tools/check_pack_lock.lua`
(no lockfile entry lacks a spec) and the dirty-checkout scan over all 78 plugin
directories. `make format-check` and `make lint` not run in this phase. No
real-TTY QA yet.

## 2026-09-04 - Neovim 0.13 upgrade phase 4: plugin-side migrations

- `nvim-treesitter`: dropped the `cmds` lazy trigger (README: "This plugin does
  not support lazy-loading") and the inert `ft` field, deleted
  `install.prefer_git` / `install.compilers` which no longer exist in
  `install.lua`, and made `build` wait on the async
  `require("nvim-treesitter").update()`. `:TSInstall` and friends now come
  from the plugin's own `plugin/nvim-treesitter.lua`.
- `nvim-treesitter-textobjects` needed no change. Rejected the plan's
  conditional `vim.g.no_plugin_maps = true`: runtime `ftplugin/help.lua`,
  `markdown.lua` and `checkhealth.lua` map `]]`/`[[` without consulting the
  flag, so it fixes nothing there, while it silently drops `K` in `:Man` and
  `<CR>`/`<C-]>` in `:help`. The `]m`/`[m` shadowing by 18 runtime ftplugins is
  real but predates 0.13 and wants per-filetype `vim.g.no_<ft>_maps`.
- LuaSnip: removed the `vimversion.ge` memoization. Upstream `ge()` is now
  arithmetic over a module-level `vim.version()` table, so the wrapper was pure
  overhead. Expansion retested: `snip_expand` inserts the node text and
  `in_snippet()` / `jumpable(1)` are true.
- `nvim-surround` pinned to `vim.version.range("4.x")`. This exposed a wrapper
  bug: `utils.pack.register` merges with `vim.tbl_deep_extend`, which rebuilds
  a table both sides define and loses its metatable, so the second registration
  of a spec turned the range into a plain table and `vim.pack` rejected it
  ("spec.version: expected string or vim.VersionRange, got table"). `version`
  is now carried by reference.
- Renamed 81 `buffer =` keys to `buf =` in keymap and autocmd opts. Kept
  `buffer` where it is not Neovim's: blink-cmp's source name, oil's keymap
  schema (`tbl_extend('keep', { buffer = bufnr }, opts)` in the plugin), and
  `maparg()`'s Vimscript return dict. Found and fixed a latent bug on the way:
  `core/lsp.lua:241` filtered `vim.lsp.get_clients` on `buffer`, a key that API
  ignores, so it matched every client instead of the attached ones; the
  documented key is `bufnr`.
- Migrated ten `nvim_win_set_height` / `nvim_win_set_width` calls to
  `nvim_win_resize(win, width, height)` with `-1` for the unchanged axis. Two
  sites passed the setter as a value and now wrap it.

Automated status: `tools/verify.sh` passes after each of the six commits.
`make format-check` still reports only the two pre-existing diffs in
`lua/plugin/agent-prompt.lua` and `tests/agent_prompt_spec.lua`. `make lint`
not run separately; `luacheck` runs inside `tools/verify.sh`. No real-TTY QA.
