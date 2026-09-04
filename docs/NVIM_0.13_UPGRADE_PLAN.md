# Neovim 0.13 upgrade and plugin migration plan

Written 2026-09-04. Evidence: `docs/NVIM_0.13_MIGRATION_RESEARCH.md` (primary
sources, cited per claim) plus the repository checks below. Follow
`docs/WORKFLOW_LOOPS.md` §Upgrade loop: one phase per branch or commit series,
`tools/verify.sh` green before moving on, every repair logged in
`bugs_fixes/ENGINEERING_LOG.md`.

## Starting point (verified 2026-09-04)

- `master` at `4f2141ed`, clean tree; `fix/dead-cwd-guards` was fast-forwarded in.
- `feat/otter-language-allowlist` is content-contained in `master` (direct diff
  shows only files `master` added later). Delete with `git branch -D`.
- Installed `NVIM v0.13.0-dev-998+g4b69d3fd2d-Homebrew` equals `nvim-version.txt`.
  `:checkhealth` says upstream HEAD is `5209695703db`; `vim.async` and
  `'previewpopup'` are not in the local build yet.
- `tools/verify.sh` passes on this baseline (log `/tmp/nvim-verify-baseline.log`).
- Plugin store `~/.local/share/nvim/site/pack/core/opt`: 87 entries, lock last
  committed 2026-07-15. `nvim-treesitter` is locked to `main` but checked out
  detached at `4916d659` (2026-04-03), 47 commits behind.

## Phase 0 — Prep

1. `git branch -D feat/otter-language-allowlist`.
2. `git push origin master` (3 commits ahead).
3. Branch `chore/nvim-0.13-upgrade`; do every phase below on it, one commit per phase.

## Phase 1 — Fix what is already broken on 0.13 (no plugin changes)

Guaranteed failures or silent misbehaviour on the current build:

1. `plugin/intro.lua:214` registers `BufModifiedSet`, removed in 0.13. Every
   interactive no-argument start hits `Invalid 'event'`. Replace with
   `{ event = "OptionSet", pattern = "modified" }`. Same fix in the disabled
   fork `lua/plugin/winbar/configs.lua:192`.
2. `lua/core/diagnostic.lua:6-8` sets `jump.callback`; the documented field is
   `on_jump`. `]d` / `[d` never open the float today.
3. `vim.F.npcall` → `vim.npcall` (deprecated 0.13, removed 0.15) in 8 files:
   `lua/plugin/winbar/utils/init.lua:7`, `lua/plugin/winbar/sources/treesitter.lua:162`,
   `lua/pack/specs/start/oil.lua:569`, `lua/pack/specs/opt/molten-nvim.lua:237`,
   `lua/pack/specs/opt/ultimate-autopair.lua:29`,
   `after/ftplugin/{markdown,rmd,quarto}/codeblock.lua:40`.
4. `lua/core/autocmds.lua:112` `vim.highlight.on_yank` → `vim.hl.hl_op`.
5. `lua/plugin/lsp-commands.lua`: `semantic_tokens.start/stop` (667, 682) →
   `semantic_tokens.enable(bool, {bufnr=, client_id=})`; `codelens.refresh/clear/
   display/save` (522-565) → rebuild the `:Lsp codelens` subcommands on
   `vim.lsp.codelens.enable()`.
6. `after/lsp/eslint.lua:76` `vim.loop` → `vim.uv`.
7. `lua/core/autocmds.lua:50-64` monkey-patches `vim.treesitter.get_parser` and
   calls private `vim.treesitter._create_parser`. 0.12 `get_parser` already
   returns `nil, err` instead of throwing. Delete the patch; nil-check callers at
   `lua/utils/ts.lua:71,134`, `lua/plugin/statusline.lua:1066`,
   `lua/pack/specs/start/dropbar.nvim.lua:89`, the three `codeblock.lua:52`.

Add to `tools/verify.sh`: a UI-less check that `plugin/intro.lua` registers no
removed event (`nvim --headless -u NONE -l` sourcing it with `vim.g.has_ui`
stubbed), and `:checkhealth vim.deprecated` must report no config-owned traceback.

## Phase 2 — Remove plugins and stale checkouts

| Remove | Why | Replacement |
|---|---|---|
| `lua/pack/specs/opt/nvim-treesitter-incremental-selection.lua` | Repo archived; author points to incselect.nvim | Built-in `v_an` / `v_in` / `v_]n` / `v_[n` (0.12); keep the spec's LSP `selectionRange` preference by mapping `vim.lsp.buf.selection_range` first. Resolve the `an`/`in` clash: mini.ai overrides them on purpose (`lua/pack/specs/opt/mini_ai.lua:12-13`); pick one owner |
| `lua/pack/specs/opt/nvterm.lua` | Unmaintained, moved, and `enabled = false` is inert in the wrapper | `lua/plugin/term.lua` already owns terminals |
| Lock-only orphans `lsp-timeout.nvim`, `nvim-lspconfig`, `smart-motion.nvim`, `snacks.nvim`, `volt`, `mini.icons`, `oil.nvim` | No spec references them; `after/lsp/*.lua` uses native `vim.lsp.config`. `oil.nvim` is a seventh orphan the first count missed: `lua/pack/specs/start/oil.lua` points at the `canola.nvim` fork, which ships the same `oil` module | `:packdel <name>` each, or `vim.pack.del({...})`, then commit the lock |

Decide, not required: `nvim-colorizer.lua` silently disables the built-in
`vim.lsp.document_color`; set `display.disable_document_color = false` to let
Neovim own LSP colours. `copilot.lua` suggestions can move to
`vim.lsp.inline_completion` later; the research marks the server-bootstrap
question unverified, so leave copilot.lua as is in this pass.

Wrapper gap to close in the same commit: `lua/utils/pack.lua` ignores
lazy.nvim-style `enabled`, `dependencies`, and `branch`. Four specs set
`enabled = false` at spec level (fluoride, nvterm, termite, themeswitcher) and
still load; noice, sidekick, and which-key only set `enabled` inside their own
setup tables, so they were miscounted here. Either implement `data.enabled` in
the wrapper or delete those specs. Convert `dependencies` → `deps` in
`diffview.lua:5`, `lazydev.lua:6`, `neogit.lua:5`, `noice.lua:5`,
`triptych.lua:7`; drop `branch` in `neogit.lua:8`.

Resolved 2026-09-04: built-in |v_an| / |v_in| own `an`/`in`; mini.ai's next and
last textobjects moved to `aN`/`iN`/`aL`/`iL`. `data.enabled` is implemented,
so fluoride, termite, and themeswitcher stay installed but no longer load —
decide in Phase 5 whether to `:packdel` them too.

## Phase 3 — Move plugins whose repositories moved (one commit, re-clones)

`vim.pack` deletes and re-clones a plugin when `src` changes, so batch these and
commit `nvim-pack-lock.json` with them.

Corrected 2026-09-04: it does not. Editing `src` alone leaves the on-disk
remote and the lockfile on the old owner even though `vim.pack.get()` reports
the new URL. Force the re-clone with `vim.pack.del()` on the six store
directories, then `:PackInstallAll`.

| Spec | New `src` |
|---|---|
| `lua/pack/specs/start/focus.lua:3` | `https://github.com/nvim-focus/focus.nvim` |
| `lua/pack/specs/opt/mini.lua:3` | `https://github.com/nvim-mini/mini.nvim` |
| `lua/pack/specs/opt/mini_ai.lua:3` | `https://github.com/nvim-mini/mini.ai` |
| `lua/pack/specs/opt/nvim-web-devicons.lua:3` and dep entries in `fzf-lua.lua:8`, `oil.lua:7`, `blink-cmp.lua:17`, `nvim-dap-ui.lua:10`, `triptych.lua:9` | `https://github.com/nvim-tree/nvim-web-devicons` |
| `lua/pack/specs/opt/nvim-colorizer.lua:3` | `https://github.com/catgoose/nvim-colorizer.lua` |
| `lua/pack/specs/opt/mason.lua:3`, `mason-tool-installer.lua:6` | `https://github.com/mason-org/mason.nvim` |

## Phase 4 — Plugin-side migrations

1. `lua/pack/specs/opt/nvim-treesitter.lua`: `main` does not support lazy-loading
   (README), so drop the `cmds` trigger; delete `ts_install.prefer_git` and
   `ts_install.compilers` (lines 45-46; fields no longer exist in `install.lua`);
   make `build` call `require("nvim-treesitter").update():wait()`. Keep
   `version = "main"`.
2. `lua/pack/specs/opt/nvim-treesitter-textobjects.lua`: already on `main`, so
   nothing to migrate. Verified 2026-09-04: do **not** set
   `vim.g.no_plugin_maps`. Runtime `ftplugin/help.lua`, `markdown.lua` and
   `checkhealth.lua` map `]]`/`[[` unconditionally and ignore the flag, so it
   would not fix those, while it *would* silently drop `K` in `:Man` and
   `<CR>`/`<C-]>` in `:help`, which this config does not redefine
   (`after/ftplugin/{man,help}.lua` only set options and `d`/`u`).
   The real clash predates 0.13: `ftplugin/python.vim` and 17 other runtime
   ftplugins map `]m`/`[m`/`]]`/`[[` buffer-locally, so the regex motion beats
   the treesitter one in those filetypes. Fixing it means per-filetype
   `vim.g.no_<ft>_maps` in `lua/core/options.lua`. Eddy's call — it is a
   preference about which motion wins, not a 0.13 correctness bug.
3. `lua/pack/specs/opt/luasnip.lua:10-16`: the `vimversion` cache patch targets
   issue #1393 (closed 2025-10); remove and retest snippet expansion.
4. `lua/pack/specs/opt/nvim-surround.lua`: optional `version = vim.version.range("4.x")`.
5. Rename `buffer=` → `buf=` in keymap and autocmd opts when touching a file
   (35 keymap sites, 13 autocmd sites listed in the research §1.1 rows 7-8).
6. `nvim_win_set_height/width` → `nvim_win_resize` starting with
   `lua/utils/win.lua:23,96,114,124`, then `lua/utils/key.lua:170,323`,
   `lua/core/autocmds.lua:345`, `lua/plugin/agent-prompt.lua:290-291`,
   `lua/pack/specs/opt/opencode.lua:114`.

## Phase 5 — Rebuild Neovim HEAD and update every plugin

1. `brew reinstall neovim --HEAD`; `nvim --version | head -3 > nvim-version.txt`;
   README line 91 says "Neovim 0.12", change to 0.13.
2. `:PackUpdateAll` (wraps `vim.pack.update()`); review, confirm. This also
   resolves the six checkouts `:checkhealth vim.pack` flags as off-lock
   (triptych, onedark, vim-fugitive, themeswitcher, termite, gruvbox-material).
   vimtex v2.18 needs Neovim ≥ 0.12.4, satisfied here.
3. `tools/verify.sh`; one breakage per loop; log each. Commit the lock separately
   from code fixes.

## Phase 6 — Manual QA and closure

1. `docs/MANUAL_QA.md` in a real TTY, plus the research's unverified items:
   statusline / statuscolumn `%=` alignment (0.13 changed item-group handling at
   `lua/plugin/statusline.lua:876,898,1080`, `statuscolumn.lua:142,150`), noice
   on 0.13 message events, `blink-cmp-rg` against blink 1.10, `vim.ui.img`
   under Ghostty. Append a dated section.
2. `make format-check && make lint`; merge to `master`; push.

Stop condition: `nvim-version.txt` matches the rebuilt HEAD, no lock entry lacks
a spec, no spec sets an inert field, `:checkhealth vim.deprecated` and
`vim.pack` are clean, `tools/verify.sh` passes, manual QA recorded.
