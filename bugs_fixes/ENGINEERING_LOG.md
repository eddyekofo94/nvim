# Engineering log

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
