# Manual Neovim QA

Verified in an isolated real TTY on 2026-07-15:

- No runtime errors after opening Markdown and Lua buffers.
- Dropbar rendered and `<leader>ls` opened its picker.
- Smart Files returned repository entries; F4/F5/F6 preview controls worked.
- Smart Files cumulative filtering preserved the `converter` file query across
  `Ctrl-G`, grep returned `converter.py` for `OVERRIDES`, `Ctrl-G` toggled back,
  `Ctrl-R` refreshed, F4 revealed the preview, and F5 expanded and restored it.
- Blink rendered Insert-mode and command-line candidates; `<C-n><CR>` selected
  and accepted the expected buffer completion.
- Mason, Fugitive, and table-mode commands opened or toggled successfully.
- Colors, statusline, winbar, folds, and window layout rendered correctly.
- Copilot stayed unloaded before Insert mode, then reported `Online` and
  `attached`, rendered an inline Lua suggestion, and installed its `<C-j>`
  accept mapping.
- Sidekick loaded on `User VeryLazy`; `<leader>as` opened its live 18-entry CLI
  selector and its toggle/select/opencode mappings remained callable without
  eagerly loading Copilot.
- Exiting each real-TTY Copilot session left zero orphaned Copilot language
  servers.

Still worth confirming during normal service- and language-dependent use:

- Blink documentation and snippet-specific completion retain their expected key
  behavior during normal language-project use.
- Fzf-lua register insertion retains the customized behavior.
- LSP attach, diagnostics, statusline, formatting, and hover work in a project.
- DAP and Molten operate against configured debuggers and kernels.
- Terminals and the complete interaction set feel unchanged in normal use.

## Swift

Verified in an isolated real TTY (`script -q /dev/null nvim …`) on 2026-08-06,
against two throwaway git fixtures — a SwiftPM package and an `xcodegen`
`.xcodeproj` macOS tool target. Both passed identically:

- `sourcekit` attached via `xcrun sourcekit-lsp`, with `root_dir` resolved to
  the package/project directory, and answered `textDocument/documentSymbol`,
  `hover`, and cross-file `definition`.
- Treesitter parsed the buffer as `swift` and produced real captures
  (`keyword`, `type`, `function.method`, `variable.member`, `string`, …).
- `swift_format` resolved to `xcrun` and reformatted the changed hunk on save
  (`let    name  :String` → `let name: String`) via `format_after_save`, which
  only formats lines present in `git diff`, so the file must be tracked.

`.xcodeproj`/`.xcworkspace` extras:

- `xcode-build-server config -project X.xcodeproj -scheme X` must have been run,
  otherwise compiler flags cover only the open file.
- `xcode-build-server` serves flags parsed from the newest `.xcactivitylog`
  build log. After adding or removing source files, an *incremental* build
  leaves stale per-file flags and cross-file symbols fail with `cannot find
  type … in scope`. Re-run `xcodebuild … clean build`, then re-run
  `xcode-build-server config`. This was observed and reproduced during this QA
  pass — it is the expected failure mode, not a config bug.

Record any failure in `bugs_fixes/ENGINEERING_LOG.md` before another repair loop.

## Neovim 0.13 upgrade — Phase 6 (2026-09-08)

Driven on branch `chore/nvim-0.13-upgrade` against
`NVIM v0.13.0-dev-1561+gb3bd442c5c-Homebrew` in a real pty
(200x50, `TERM=xterm-256color`, `TERM_PROGRAM=ghostty`) spawned by a
`pty.openpty` harness, with each step scheduled through the main loop
(`vim.defer_fn`) so typed keys are processed, and the rendered grid read back
with `screenstring()`. The only message in every session was
`E1568: Terminal did not respond to DSR request for 'background' color`, which
is the harness (no terminal answers queries), not the config.

Verified:

- Opening `lua/core/options.lua` and `docs/MANUAL_QA.md` produced no errors;
  treesitter parser and highlighter active for `lua`; `catppuccin` with
  `termguicolors`.
- Dropbar rendered in the winbar; `<leader>ls` entered pick mode and showed its
  accelerator letters, `<Esc>` left it.
- `'statusline'` `%=` survives the 0.13 item-group change:
  `nvim_eval_statusline` returns `width = 200 = &columns`, the left group stays
  left and the right group is flush right on the drawn row; in a 40-column
  window both the active and inactive statusline evaluate to exactly 40 with
  the `%<` truncation marker. No group-internal `%=` was ignored.
- `'statuscolumn'` `%=` alignment holds: every `use_statuscol_lnum` evaluation
  is 7 cells wide, relative numbers right-aligned, the current absolute line
  left-aligned, and the drawn columns match the evaluation.
- blink.cmp (`v1.10.0-233-g49d39fda`) showed 10 insert-mode items, `<C-n>`
  then `<CR>` accepted `local`, and the cmdline menu showed 80 items for `:ed`.
- `blink-cmp-rg.nvim` works against blink 1.10: with the spec's `ripgrep`
  provider options, 35 items came back, 33 of them from source `ripgrep`
  (for example `statusline`). The research's `UNVERIFIED` row is now closed.
- noice.nvim consumes 0.13 message events: `:Noice history` recorded
  `msg_show` and `msg_show.echomsg` entries, the `cmdline` view rendered on the
  bottom row, the `mini` view rendered notifications, `:lua error(...)` was
  routed, and no error surfaced. `require('noice.view').get_views()` does not
  exist — that is an API assumption in the QA script, not a noice fault.
- LSP: `lua-language-server` attached, `vim.lsp.buf.hover()` opened a float,
  four diagnostics were produced, and `]d` opened the diagnostic float, which
  confirms the Phase 1 `jump.on_jump` fix. `:Lsp codelens_is_enabled`,
  `codelens_enable`, `codelens_disable`, `semantic_tokens_enable` and
  `semantic_tokens_disable` all ran clean on the rebuilt 0.13 API.
- conform resolved `stylua` for Lua buffers.
- Copilot stayed unloaded until Insert mode, then loaded with one LSP client
  and its `<C-j>` "accept suggestion" insert mapping; exactly one Copilot
  server ran during the session and zero survived exit. No inline suggestion
  rendered inside the harness.
- Sidekick loaded on `User VeryLazy` and `<leader>as` opened its selector
  float (200x10); the float's contents did not render in this harness.
- `:Mason` opened its `mason` buffer, `:Git` opened fugitive, and
  `:TableModeToggle` toggled. `:terminal` opened, echoed and closed cleanly.
- `tools/verify.sh` passed end to end (41 agent-prompt assertions included).

### Ghostty session pass (2026-09-08)

Run by Eddy in a real Ghostty window on `chore/nvim-0.13-upgrade`, closing the
fzf-lua gap the pty harness could not reach.

First attempt crashed on every picker:

```
[Fzf-lua] fn_selected threw an error: [string "vim/keymap"]:109:
Invalid 'buf': Expected Lua number
  .../lua/pack/specs/start/fzf-lua.lua:1584: in function 'fzf_on_create'
```

Cause: Neovim 0.13 added `buf` to `vim.keymap.set` and requires an **integer**;
only the soft-deprecated `buffer` still accepts `true`. fzf-lua calls
`on_create` without `args.bufnr`, so `buf = args and args.bufnr or true` passed
a boolean. Fixed in four files — `lua/pack/specs/start/fzf-lua.lua:1565,1575,1581,1590`
(now the `_term_buf` computed at `:1546`), `lua/pack/specs/opt/vim-fugitive.lua:113-125`
(5 sites), `lua/pack/specs/opt/molten-nvim.lua:442`, and `lua/utils/key.lua:45,66,72`,
where `M.get()` returned a boolean `buf` that `M.amend()` fed to `vim.keymap.set`
at `:739`. `lua/utils/load.lua:355` already normalized `opts.buf == true and 0`.

Verified after the fix:

- `<Leader><Leader>` and Smart Files (`<Leader>.`) open and list recent files;
  the `fzf` process attaches. No error.
- `F4` / `F5` / `F6` preview controls all work.
- `<C-g>` files/grep toggle works across three rounds.
- `<C-r>` terminal-mode register insertion works.

Gate commands after the fix: `tools/verify.sh` passed (41 agent-prompt
assertions), `make lint` 0 warnings / 0 errors in 477 files, `make format-check`
clean.

### `:checkhealth vim.pack` cleanup (2026-09-08)

`:checkhealth vim.pack` reported 13 warnings / 0 errors, every one of them
"Plugin X is not at state which is a result of `vim.pack` operation":
`termite.nvim`, `themeswitcher.nvim`, `todo-comments.nvim`, `triptych.nvim`,
`ultimate-autopair.nvim`, `vim-conjoin`, `vim-dispatch`, `vim-easy-align`,
`vim-fugitive`, `vim-projectionist`, `vim-rhubarb`, `vim-sleuth`,
`vim-table-mode`.

`vim.pack.update({...}, { offline = true })` on all 13, after `PackInstallAll`
registered every spec, reported `Nothing to update` — so each was already at the
correct revision — and the 13 warnings survived it.

The health check at
`$VIMRUNTIME/lua/vim/pack/health.lua:260-273` only tests whether
`git rev-parse --abbrev-ref HEAD` returns `HEAD`; `vim.pack` always leaves a
plugin detached, so any named branch trips it. All 13 were on a branch (`main`,
`master`, or `v0.6` for `ultimate-autopair.nvim`) with a clean worktree. Running
`git checkout --detach` in each left every commit hash unchanged.

After that: `:checkhealth vim.deprecated` and `:checkhealth vim.pack` are both
✅ with 0 warnings / 0 errors, and `tools/verify.sh` passes (41 agent-prompt
assertions). This is plugin-checkout state on disk, not a config change, so
nothing in this repository changed for it.

### `vim.ui.img` under Ghostty (2026-09-08)

`:lua print(vim.ui.img._supported())` in a real Ghostty window printed
`true nil` — supported, with no second return value. The pty harness reported
`false` only because nothing there answers the kitty APC graphics query, so the
harness result was an artifact, not a config problem.

This build still has no `vim.ui.img` healthcheck ("No healthcheck found for
\"vim/ui/img\" plugin"), so the research's `:checkhealth vim.ui.img`
expectation in `docs/NVIM_0.13_MIGRATION_RESEARCH.md` remains stale.

Not verified here — needs a human in Ghostty:

- noice against a real `msg_show.progress` stream from a long LSP job; only
  synthetic messages were exercised.
- Blink documentation and snippet keys, DAP, and Molten, as before.

Gate commands: `tools/verify.sh` and `make lint` pass (0 warnings / 0 errors in
477 files). `make format-check` failed on `lua/plugin/agent-prompt.lua` and
`tests/agent_prompt_spec.lua`; the same two files also fail on `master`, so
this is stylua 2.5.2 drift that predates the upgrade, not a 0.13 regression. It
was fixed with `make format` in this branch.
