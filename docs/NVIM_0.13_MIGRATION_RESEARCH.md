# Neovim 0.13-dev migration research for this config

Date: 2026-09-04. Scope: what changed in Neovim between the config's last
recorded targets (v0.12.0-dev-2101, Feb 2026, then v0.13.0-dev-998, Jul 2026)
and today, what each of the 78 requested plugins now requires, and which
built-ins make plugins redundant. Every claim cites a primary source (Neovim
`runtime/doc/*.txt`, the plugin's own README/release notes, the GitHub API, or
a command run on this machine). Anything not verified against such a source is
marked `UNVERIFIED`.

Installed build on this machine (`nvim --version`, `brew list --versions neovim`):

```
NVIM v0.13.0-dev-998+g4b69d3fd2d-Homebrew   (brew: neovim HEAD-4b69d3f)
```

`nvim-version.txt` already records this exact string. `:checkhealth` reports
`Build is outdated. Local: 4b69d3fd2d, HEAD: 5209695703db` — so a few items in
upstream `news.txt` (`vim.async`, `'previewpopup'`) are **absent** from the
local binary (verified by headless probe below).

Neovim 0.12 stable releases (https://github.com/neovim/neovim/releases):
v0.12.0 2026-03-29, v0.12.1 04-06, v0.12.2 04-22, v0.12.3 06-10, v0.12.4 07-05,
v0.12.5 08-23. The config skipped straight from 0.12-dev to 0.13-dev, so
everything in `news-0.12.txt` and `deprecated-0.12` applies as well.

Source shorthands used below:

- `news13` = https://github.com/neovim/neovim/blob/master/runtime/doc/news.txt (also read locally at `/opt/homebrew/Cellar/neovim/HEAD-4b69d3f/share/nvim/runtime/doc/news.txt`)
- `news12` = https://github.com/neovim/neovim/blob/master/runtime/doc/news-0.12.txt
- `news11` = https://github.com/neovim/neovim/blob/master/runtime/doc/news-0.11.txt
- `news10` = https://github.com/neovim/neovim/blob/master/runtime/doc/news-0.10.txt
- `dep` = https://github.com/neovim/neovim/blob/master/runtime/doc/deprecated.txt
- `pack` = https://github.com/neovim/neovim/blob/master/runtime/doc/pack.txt
- `lsp` = https://github.com/neovim/neovim/blob/master/runtime/doc/lsp.txt (`*lsp-defaults*`)
- `vim_diff` = https://github.com/neovim/neovim/blob/master/runtime/doc/vim_diff.txt (`*default-mappings*`)
- `probe` = `/tmp/apicheck.lua` run with `nvim --headless --clean -l` on this machine (output reproduced in §3.3)

---

## Summary

1. **One live startup error on 0.13**: `BufModifiedSet` was removed
   (`news13` BREAKING/EVENTS; probe: `nvim_create_autocmd('BufModifiedSet')`
   → `Invalid 'event'`). `plugin/intro.lua:214` registers it whenever Neovim
   starts interactively with no file argument. Replace with `OptionSet`
   pattern `modified`.
2. **Deprecation warning already firing**: `vim.F.npcall` (deprecated 0.13,
   removed 0.15) is used in 8 config files and in `dropbar.nvim` master
   (`:checkhealth vim.deprecated` traceback). Replace with `vim.npcall`.
3. **Silent misconfiguration**: `lua/core/diagnostic.lua:6-8` sets
   `jump = { callback = ... }`; the documented field is `on_jump`
   (`diagnostic.txt` `*vim.diagnostic.Opts.Jump*`). `]d`/`[d` never open the float.
4. **Deprecated LSP calls still in the config**: `vim.lsp.semantic_tokens.start/stop`
   and `vim.lsp.codelens.refresh/clear/display/save` (both `deprecated-0.12`) in
   `lua/plugin/lsp-commands.lua`; `vim.highlight.on_yank` (deprecated 0.11, and
   `vim.hl.on_yank` again in 0.13 → `vim.hl.hl_op`) in `lua/core/autocmds.lua:112`.
5. **Seven repos moved (HTTP 301)**: focus.nvim → `nvim-focus`, mini.nvim /
   mini.ai / mini.icons → `nvim-mini`, nvim-web-devicons → `nvim-tree`,
   nvim-colorizer.lua → `catgoose`, nvterm → `zbirenbaum`, mason.nvim →
   `mason-org`. `vim.pack` re-clones when `src` changes (`pack` §add), so plan
   the URL edits as one batch.
6. **One archived plugin**: `shushtain/nvim-treesitter-incremental-selection`
   (GitHub API `archived: true`; README: "Deprecated in favor of incselect.nvim").
   Neovim 0.12 ships `v_an`/`v_in`/`v_]n`/`v_[n` natively (`news12` TREESITTER),
   and mini.ai deliberately overrides `an`/`in` — three claimants for the same keys.
7. **nvim-treesitter is already on `main`** (spec + lockfile), which requires
   Neovim 0.12+ and does not support lazy-loading (README). `master` is locked
   for 0.11 only. The spec still lazy-loads on commands.
8. **Built-ins now overlap**: `vim.lsp.document_color` (colorizer),
   `vim.lsp.inline_completion` (copilot.lua suggestions), native incremental
   selection (tsis), `:DiffTool` (partial diffview), `vim.pack` (mini.deps is
   frozen upstream), built-in `gc`/`:Inspect`/`vim.snippet`/foldexpr (already used).
9. **Lockfile drift**: six plugins on disk are not at the locked revision
   (triptych, onedark, vim-fugitive, themeswitcher, termite, gruvbox-material)
   and seven lock entries have no spec (lsp-timeout, nvim-lspconfig,
   smart-motion, snacks, volt, mini.icons, plenary — plenary is a real dep).
10. **Wrapper gaps**: `lua/utils/pack.lua` honours `data.deps`/`data.exts` only;
    `data.enabled = false`, `data.dependencies`, and `data.branch` (lazy.nvim
    fields used in 10 specs) are inert.

---

## 1. Neovim breaking changes, removals, and deprecations

### 1.1 Table: change → where the config is affected → action

| # | Change (version) | Source | Affects (file:line) | Action |
|---|---|---|---|---|
| 1 | `BufModifiedSet` event removed; use `OptionSet` pattern `modified` | `news13` BREAKING → EVENTS; `dep` 0.13 EVENTS; probe error `Invalid 'event': 'BufModifiedSet'` | `plugin/intro.lua:214` (runs when `vim.g.has_ui and argc()==0`, line 23); `lua/plugin/winbar/configs.lua:192` (local winbar is disabled in `plugin/_load.lua:43-45`) | Replace with `{ event = "OptionSet", pattern = "modified" }` (dropbar README shows the same swap) |
| 2 | `vim.F.npcall` → `vim.npcall`; `vim.F.if_nil` → `vim.nonnil`; `vim.F.nil_wrap`, `vim.F.ok_or_nil` deprecated (0.13, removed 0.15) | `dep` 0.13 LUA; `:checkhealth vim.deprecated` on this machine | `lua/plugin/winbar/utils/init.lua:7`, `lua/plugin/winbar/sources/treesitter.lua:162`, `lua/pack/specs/start/oil.lua:569`, `lua/pack/specs/opt/molten-nvim.lua:237`, `lua/pack/specs/opt/ultimate-autopair.lua:29`, `after/ftplugin/markdown/codeblock.lua:40`, `after/ftplugin/rmd/codeblock.lua:40`, `after/ftplugin/quarto/codeblock.lua:40`; upstream: dropbar `lua/dropbar/sources/treesitter.lua:176` (master 808ba31, still unfixed) | `vim.npcall` (present on this build per probe) |
| 3 | `vim.highlight` → `vim.hl` (0.11); `vim.hl.on_yank()` → `vim.hl.hl_op()` (0.13). Probe printed `vim.hl.on_yank is deprecated` | `dep` 0.11 LUA, `dep` 0.13 HIGHLIGHTS | `lua/core/autocmds.lua:112` (`pcall(vim.highlight.on_yank, …)`) | Use `vim.hl.hl_op` (present per probe) |
| 4 | `vim.lsp.semantic_tokens.start()/stop()` → `enable(true/false)` (0.12; also listed under BREAKING "Renamed … to enable()") | `news12` BREAKING LSP; `dep` 0.12 LSP | `lua/plugin/lsp-commands.lua:667`, `:682` | `vim.lsp.semantic_tokens.enable(bool, {bufnr=, client_id=})` |
| 5 | `vim.lsp.codelens.refresh/clear/display/save/on_codelens` deprecated → `codelens.enable()` (0.12) | `dep` 0.12 LSP | `lua/plugin/lsp-commands.lua:522, 531, 553, 565` | Rewrite the `:Lsp codelens …` subcommands on `vim.lsp.codelens.enable()`; also note `grx` default maps `codelens.run()` (`news12` DEFAULTS) |
| 6 | `vim.diagnostic.Opts.Jump` fields are `on_jump`, `severity`, `wrap`; `"float"` in JumpOpts deprecated → `on_jump` (0.12) | `diagnostic.txt` `*vim.diagnostic.Opts.Jump*` (installed build); `dep` 0.12 DIAGNOSTICS | `lua/core/diagnostic.lua:6-8` uses `callback = vim.diagnostic.open_float` — not a documented field, so it is ignored | Change to `on_jump = function(_, bufnr) vim.diagnostic.open_float({bufnr = bufnr}) end` |
| 7 | `"buffer"` in `vim.keymap.set.Opts` / `del.Opts` renamed to `"buf"` (0.12). Probe: `buffer=` still works, no warning emitted | `dep` 0.12 LUA; `lua.txt` `vim.keymap.set()` documents `{buf}` | 35 call sites, e.g. `lua/core/autocmds.lua:247`, `lua/plugin/term.lua:372,383`, `lua/plugin/agent-prompt.lua:271`, `lua/plugin/winbar/menu.lua:469,472`, `lua/pack/specs/opt/molten-nvim.lua:482-484` | Low priority: mechanical rename to `buf` when touching those files |
| 8 | `"buffer"` key of `nvim_create_autocmd/get/exec/clear_autocmds` renamed to `"buf"` (0.13). No runtime warning observed | `dep` 0.13 API | `lua/core/lsp.lua:28,41,46`, `lua/core/autocmds.lua:166`, `lua/plugin/jupytext.lua:245`, `lua/utils/load.lua:160`, `lua/utils/stl.lua:231`, `lua/pack/specs/start/oil.lua:604`, `lua/pack/specs/start/fzf-lua.lua:1548`, `lua/pack/specs/opt/vimtex.lua:44`, `lua/pack/specs/opt/vim-fugitive.lua:94`, `lua/pack/specs/opt/molten-nvim.lua:454`, `after/ftplugin/{markdown,quarto}/title.lua:143`, winbar files | Same as #7 |
| 9 | `nvim_win_set_height()/width()` → `nvim_win_resize()` (0.13). `nvim_win_resize` present per probe | `dep` 0.13 API; `news13` API | `lua/core/autocmds.lua:345`, `lua/plugin/agent-prompt.lua:290-291`, `lua/pack/specs/opt/opencode.lua:114`, `lua/utils/win.lua:23,96,114,124`, `lua/utils/key.lua:170,323` | Migrate `lua/utils/win.lua` helpers first; others follow |
| 10 | `vim.loop` → `vim.uv` (0.10) | `dep` 0.10 LUA | `after/lsp/eslint.lua:76` | `vim.uv.os_uname()` |
| 11 | `vim.treesitter.get_parser()` returns `nil, err` instead of throwing (0.12) | `news12` line 462-463; `treesitter.txt` `get_parser()` "If no parser can be created, nil (and an error message) is returned" | `lua/core/autocmds.lua:50-64` monkey-patches `get_parser` and calls private `vim.treesitter._create_parser`; `lua/utils/ts.lua:71,134`; `lua/plugin/statusline.lua:1066`; `after/ftplugin/{markdown,rmd,quarto}/codeblock.lua:52`; `lua/pack/specs/start/dropbar.nvim.lua:89` | `pcall` wrappers are harmless but callers must nil-check the result; the `_create_parser` use is private API (risk, no doc) |
| 12 | `vim.lsp.handlers` deprecated for client→server response handlers (0.11) | `dep` 0.11 LSP | `lua/core/lsp.lua:101-103` overrides `vim.lsp.handlers[method]` | Review whether the wrapped methods are server-to-client (still supported) |
| 13 | `'statusline'`/`'statuscolumn'`/`'winbar'`/`'tabline'` `%=` no longer ignored inside item groups; truncation of groups changed (0.13) | `news13` BREAKING OPTIONS | `lua/plugin/statusline.lua:876,898,1080`; `lua/plugin/statuscolumn.lua:142,150` emit `%=` | `UNVERIFIED` whether those `%=` land inside a `%(…%)` group; visually check numbers/alignment |
| 14 | `vim.o`/`vim.opt`/`nvim_set_option_value()` now expand `~` and `$ENV` (0.13) | `news13` BREAKING API | grep found no option assignment containing `~` or `$` | None |
| 15 | `vim.opt` no longer supports chained infix operators (0.13) | `news13` BREAKING LUA | grep found none | None |
| 16 | `vim.diagnostic.Opts.Status.format` no longer accepts severity→text table; `current_line` for virtual_lines/virtual_text now applied on `CursorHold` (0.13) | `news13` BREAKING DIAGNOSTICS | Config does not set `status.format` or `current_line` | None; diagflow owns inline diagnostics (`lua/core/diagnostic.lua:15`) |
| 17 | `vim.lsp.ClientConfig.cmd` (list form) now uses `root_dir` as cwd; `client.attached_buffers[buf]` stores `languageId` string (0.13) | `news13` BREAKING LSP | `after/lsp/*.lua` (no cwd assumptions found) | None |
| 18 | `stdpath("log")` moved to `stdpath("state")/logs` (0.13) | `news13` BREAKING EDITOR | None in config (checkhealth already shows `~/.local/state/nvim/logs/lsp.log`) | None |
| 19 | `vim.diff()` → `vim.text.diff()` (0.12) | `news12` BREAKING LUA | None | None |
| 20 | Decoration provider `on_line` → `on_range` (0.12) | `dep` 0.12 API | None | None |
| 21 | Removed in 0.12: `vim.diagnostic.disable/is_disabled`, legacy `enable(buf, ns)`, `:sign-define` diagnostic signs | `news12` BREAKING DIAGNOSTICS; probe ABSENT | None (config uses `signs.text`, `vim.diagnostic.enable(false, {...})` at `lua/plugin/lsp-commands.lua:773`) | None |
| 22 | Already-removed (probe ABSENT): `vim.tbl_islist`, `vim.tbl_add_reverse_lookup`, `vim.lsp.buf_get_clients`, `vim.lsp.get_active_clients`, `vim.lsp.with`, `vim.lsp.buf.completion`, `vim.lsp.buf.execute_command`, `vim.lsp.util.jump_to_location/get_progress_messages/parse_snippet`, `vim.treesitter.query.get_query` | `dep` 0.10/0.11; probe | None in config or specs | None |
| 23 | Still present but deprecated (probe present): `vim.tbl_flatten`, `vim.region`, `vim.lsp.start_client`, `vim.lsp.stop_client`, `vim.lsp.client_is_stopped`, `vim.lsp.get_buffers_by_client_id`, `vim.lsp.set_log_level`, `vim.lsp.get_log_path`, `vim.lsp.util.stylize_markdown`, `vim.lsp.util.character_offset`, `vim.diagnostic.goto_next/prev`, `client.request()` (dot form → `Client:request()`) | `dep` 0.11/0.12/0.13 | None in config | None |
| 24 | `vim.validate(opts: table)` form deprecated (0.11) | `dep` 0.11 LUA | grep found no `vim.validate` in config | None |
| 25 | `vim.fn.jobstart` is not deprecated; `vim.system()` is the Lua alternative; `termopen()` → `jobstart({term=true})` (0.11) | `dep` 0.11 VIMSCRIPT; `news10` | `lua/core/keymaps.lua:94,104`, `lua/plugin/tmux.lua:31` use `jobstart{detach=true}` | Optional: `vim.system({...}, {detach=true})` |
| 26 | Vimscript `ctxget()/ctxpop()/ctxpush()/ctxset()/ctxsize()` removed (0.13) | `news13` BREAKING VIMSCRIPT | None | None |
| 27 | Diagnostic `"all"` option to `Query:iter_matches()` removed; `offset!` directive semantics changed (0.12) | `news12` BREAKING TREESITTER | No custom `iter_matches(..., {all=})` found | None |

### 1.2 vim.pack API on this build (`pack`, installed `pack.txt`)

- `vim.pack.add({specs}, {opts})`: `opts.confirm` (default `true`), `opts.load`
  (`boolean|fun(plug_data)`, default `false` while `init.lua` is sourcing, `true`
  after). "If exists, check if its `src` is the same as input. If not — delete
  immediately to clean install from the new source." (relevant to the URL moves below).
- `vim.pack.Spec` fields: `src` (required), `name?`, `version?`
  (`string|vim.VersionRange`: `nil` = default branch; string = branch/tag/commit;
  `vim.version.range()` = greatest semver tag), `data?` (any).
- `vim.pack.update({names}, {opts})`, `vim.pack.del({names}, {opts})`,
  `vim.pack.get({names}, {opts})` (now includes pending-update revision; `news13` LUA).
- New Ex commands in 0.13: `:packupdate[!] [++offline] [++lockfile] [name]`,
  `:packdel[!] {name}` / `++all` (`news13` EDITOR; `pack` `*:packupdate*`).
- New option `'packlockfile'` (default `$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json`),
  "Must be set before the first usage of any vim.pack function" (`options.txt`; `news13` OPTIONS).
- Events `PackChangedPre`/`PackChanged` with `data.active|kind|spec|path`
  (`pack` `*vim.pack-events*`). `lua/utils/pack.lua:373-380` already hooks `PackChanged`
  and strips Lua functions out of `data` before handing specs to `vim.pack` (native_spec).
- Lockfile format: `{"plugins": {name: {rev, src, version?}}}`; string versions are
  serialised as `'main'` (with quotes) by `lock_write()` in
  `runtime/lua/vim/pack.lua` (`("'%s'"):format(version)`), so the quotes in
  `nvim-pack-lock.json` are expected, not corruption. "Lockfile should not be
  edited by hand."

### 1.3 Default keymaps/options that make plugin keymaps redundant

From `vim_diff` `*default-mappings*`, `lsp` `*lsp-defaults*`, `news11`/`news12` DEFAULTS:

- LSP (global, unconditional): `gra` (n,v) code_action, `gri` implementation,
  `grn` rename, `grr` references, `grt` type_definition (0.12), `grx`
  codelens.run (0.12), `gO` document_symbol, `<C-S>` (i,s) signature_help,
  `K` hover (unless `keywordprg` customised), `gx` follows `documentLink`.
- Buffer-local on attach: `omnifunc`, `tagfunc`, `formatexpr` (`gq`),
  `vim.lsp.document_color` enabled by default.
- Diagnostics: `]d`/`[d` (accept count), `[D`/`]D`, `<C-W>d`.
- Unimpaired-style: `[q ]q [Q ]Q`, `[l ]l`, `[t ]t`, `[a ]a`, `[b ]b`, `[<Space> ]<Space>`.
- `gc`/`gcc` commenting (`news10` "Nvim now includes commenting support").
- Treesitter (0.12): `v_an`/`v_in` incremental selection, `v_]n`/`v_[n`;
  0.13 adds `v_]N`/`v_[N` (sibling) and `vim.treesitter.select()`; `v_al`/`v_il`
  select buffer/line (`news13` EDITOR).
- Snippets: `<Tab>`/`<S-Tab>` jump when `vim.snippet` is active (`news11`).
- Options with defaults changed in 0.12: `'diffopt'` +`indent-heuristic,inline:char`,
  `'statusline'` shows `vim.diagnostic.status()`/`vim.ui.progress_status()`,
  `'exrc'` walks parent dirs, treesitter highlighting enabled for Markdown.

### 1.4 Built-in features that replace plugins (existence verified by probe)

| Built-in | Since | Plugin(s) it overlaps |
|---|---|---|
| `vim.lsp.document_color` (on by default) | 0.12 | nvim-colorizer.lua (LSP colours part only) |
| `vim.lsp.inline_completion` (`textDocument/inlineCompletion`) | 0.12 | copilot.lua `suggestion` module (sidekick README: "use copilot.lua or native `vim.lsp.inline_completion`") |
| `v_an`/`v_in`/`v_]n`/`v_[n`, `vim.lsp.buf.selection_range` fallback | 0.12 | nvim-treesitter-incremental-selection |
| `vim.lsp.completion.enable()` (+`cmp`, colored items, preview), `'autocomplete'`, `'pumborder'`, `'pummaxwidth'` | 0.11/0.12 | blink.cmp (partial; blink still needed for sources like ripgrep/snippets) |
| `vim.lsp.linked_editing_range`, `vim.lsp.on_type_formatting` | 0.12 | none installed (ts-autotag renames tags via treesitter, not LSP) |
| `vim.lsp.foldexpr()`, `vim.treesitter.foldexpr()` | 0.11/0.10 | already used (`lua/core/treesitter.lua:55`) |
| `vim.snippet` | 0.10 | LuaSnip remains for snippet authoring; `<Tab>` jump default exists |
| `gc` commenting, `:Inspect`, `:InspectTree` | 0.10 | none installed |
| `'statuscolumn'` | 0.9 | already used (`lua/plugin/statuscolumn.lua`) |
| `virtual_lines` diagnostics + `current_line` | 0.11 | diagflow.nvim (different presentation: top-right float) |
| `vim.pack` + `:packupdate`/`:packdel` | 0.12/0.13 | mini.deps (frozen upstream, mini.nvim v0.18.0 notes) |
| `:DiffTool`, `:Undotree` | 0.12 | diffview.nvim (directory/file diff only, not git-history UI) |
| `vim.ui.img` | 0.13 | img-clip/molten image display (`:checkhealth vim.ui.img` → "Graphics protocol: not supported by this terminal" in headless; `UNVERIFIED` under ghostty interactively) |
| `vim.ui.open`, `gx` on URLs | 0.10 | none |
| `vim.lsp.semantic_tokens` (multiline, range) | 0.9/0.12 | already used |
| `:restart`, `ZR` (session-preserving in 0.13) | 0.12/0.13 | none |
| `vim.async` | HEAD only | **absent on local build 4b69d3fd** (probe) |

---

## 2. Plugin-by-plugin status

Data columns come from `gh api repos/<owner>/<repo>` (archived, default branch,
`pushed_at`), `curl -sI https://github.com/<old>` (301 target), README fetched
via `gh api repos/<repo>/readme`, and `gh api repos/<repo>/releases`.
"Lock rev" compares `nvim-pack-lock.json` against the default branch via
`gh api repos/<repo>/compare/<branch>...<rev>`.

### 2.1 Plugins to remove (reason + built-in replacement)

| Plugin | Evidence | Replacement |
|---|---|---|
| `shushtain/nvim-treesitter-incremental-selection` | GitHub API `archived: true`; README: "Deprecated in favor of incselect.nvim" (https://github.com/shushtain/incselect.nvim, not archived, pushed 2025-12-29) | Neovim 0.12 `v_an`/`v_in`/`v_]n`/`v_[n` (`news12` TREESITTER; `lsp` defaults fall back to `selection_range`). The spec (`lua/pack/specs/opt/nvim-treesitter-incremental-selection.lua:20-35`) already prefers LSP `selectionRange`, which the built-in does too. Resolve the `an`/`in` clash with mini.ai (`lua/pack/specs/opt/mini_ai.lua:12-13`; mini.ai README: "This (deliberately) overrides Neovim>=0.12 built-in incremental selection mappings") |
| `NvChad/nvterm` | README title "NvChad terminal Plugin ( Unmaintained )"; last push 2024-03-09; 301 → `zbirenbaum/nvterm`; spec has `enabled = false`, which the wrapper ignores (no `enabled` handling in `lua/utils/pack.lua`) | `lua/plugin/term.lua` (own terminal module) or `ruicsh/termite.nvim` already in specs |
| Lock-only orphans: `hinell/lsp-timeout.nvim` (pushed 2025-04), `neovim/nvim-lspconfig` (config uses native `vim.lsp.config`, `docs/IOS_DEV_RESEARCH.md` confirms), `FluxxField/smart-motion.nvim`, `folke/snacks.nvim`, `nvzone/volt`, `nvim-mini/mini.icons` | Present in `nvim-pack-lock.json` and on disk at `~/.local/share/nvim/site/pack/core/opt/`, no spec references them (grep of `lua/`, `plugin/`, `init.lua`) | `:packdel <name>` (0.13) or `vim.pack.del({...})` |
| `NvChad/nvim-colorizer.lua` LSP part only (keep the plugin for hex/rgb/hsl) | README §"Neovim built-in LSP document colors (0.12+)": colorizer "automatically disables `vim.lsp.document_color` on buffer attach via `display.disable_document_color` (default `true`)" | Decide: keep built-in (`disable_document_color = false`) or keep colorizer's LSP integration; current spec sets neither |
| `zbirenbaum/copilot.lua` `suggestion` module (optional) | copilot.lua README requires Neovim 0.11+; sidekick README lines 172-207 show `vim.lsp.inline_completion.get()` as the native alternative; v3.0.0 (2026-06-11) breaking: "remove support for apps.json" | `vim.lsp.inline_completion.enable()` with the Copilot LSP (`news12` LSP). `UNVERIFIED`: whether copilot.lua's own LSP bootstrap is still needed to obtain the server binary |

### 2.2 Plugins to move to a new URL (all verified as HTTP 301 from the old URL)

| Spec file | Old `src` | Canonical URL | Lock rev vs new default branch |
|---|---|---|---|
| `lua/pack/specs/start/focus.lua:3` | `beauwilliams/focus.nvim` | https://github.com/nvim-focus/focus.nvim (master, pushed 2026-02-08) | identical |
| `lua/pack/specs/opt/mini.lua:3` | `echasnovski/mini.nvim` | https://github.com/nvim-mini/mini.nvim (main, v0.18.0 2026-06-21) | behind 33 |
| `lua/pack/specs/opt/mini_ai.lua:3` | `echasnovski/mini.ai` | https://github.com/nvim-mini/mini.ai | not compared |
| `lua/pack/specs/opt/nvim-web-devicons.lua:3` and dep entries in `fzf-lua.lua:8`, `oil.lua:7`, `blink-cmp.lua:17`, `nvim-dap-ui.lua:10` | `kyazdani42/nvim-web-devicons` | https://github.com/nvim-tree/nvim-web-devicons (master) | behind 3 |
| `lua/pack/specs/opt/nvim-colorizer.lua:3` | `NvChad/nvim-colorizer.lua` | https://github.com/catgoose/nvim-colorizer.lua (master, pushed 2026-07-14) | identical |
| `lua/pack/specs/opt/mason.lua:3`, `mason-tool-installer.lua:6` | `williamboman/mason.nvim` | https://github.com/mason-org/mason.nvim (main, v2.3.1 2026-06-11) | identical |
| `lua/pack/specs/opt/nvterm.lua:3` | `NvChad/nvterm` | https://github.com/zbirenbaum/nvterm | remove instead (§2.1) |
| lock entry `mini.icons` | `echasnovski/mini.icons` | https://github.com/nvim-mini/mini.icons | orphan (§2.1) |

Case-only differences (`dnlhc/glance.nvim` → API reports `DNLHC/glance.nvim`;
`HakonHarnes/img-clip.nvim` → `hakonharnes/img-clip.nvim`) return HTTP 200, no
change needed.

`pack` §add: changing `src` makes `vim.pack` delete and re-clone the directory,
so these edits should be made together with a lockfile commit.

### 2.3 Plugins needing migration (branch, API, or version bump)

| Plugin | What changed | Source | Config impact |
|---|---|---|---|
| `nvim-treesitter/nvim-treesitter` | `main` is "a full, incompatible, rewrite"; requires "Neovim 0.12.0 or later", `tree-sitter-cli` 0.26.1+, C compiler; "This plugin does not support lazy-loading"; `master` "is locked but will remain available for backward compatibility with Nvim 0.11" (last master commit 2026-03-23). API on main: `require('nvim-treesitter').setup{install_dir=}`, `.install()`, `.update()`, `.uninstall()`, `.get_installed()`, `.get_available()`, `.indentexpr()` | README main; `lua/nvim-treesitter/init.lua` and `install.lua` on main | Spec `lua/pack/specs/opt/nvim-treesitter.lua` already sets `version = "main"` but (a) lazy-loads on `TSInstall…` commands (contradicts README), (b) sets `ts_install.prefer_git` / `ts_install.compilers` (lines 45-46) — those fields do not exist in main's `install.lua` (only `install/update/uninstall/get_package_path`), (c) `build` calls `require("nvim-treesitter.install").update()` which is async on main (`a.async`), use `:wait()` per README. Lock rev 4916d659 (2026-04-03) is 47 commits behind main |
| `nvim-treesitter/nvim-treesitter-textobjects` | `main` branch (default) uses `require("nvim-treesitter-textobjects").setup{select=…}` plus `…textobjects.move/swap/select` modules; README suggests `vim.g.no_plugin_maps = true` to avoid built-in ftplugin map clashes | README main | Spec already on `main` and uses `move`/`swap` modules (`lua/pack/specs/opt/nvim-treesitter-textobjects.lua:11-35`). Lock rev 851e8653 (2026-04-07) is 4 behind main |
| `lervag/vimtex` | "VimTeX requires Vim version 9.2 or Neovim version 0.12.4. The requirements were updated in July 2026 after the release of VimTeX 2.18" (v2.18 tag 2026-07-22) | README §Requirements; releases | Lock rev a5949d28 (2026-07-05) predates v2.18 and is 53 behind master; updating is fine on this 0.13 build |
| `kylechui/nvim-surround` | v4.0.0 (2026-02-22) BREAKING "Make `setup` optional"; README vim.pack snippet: `version = vim.version.range("4.x")` | releases v4.0.0; README | Lock rev 8b47db61 = main head (identical). Optional: pin `version = vim.version.range("4.x")` |
| `lewis6991/gitsigns.nvim` | v2.0.0 (2026-01-09) BREAKING "remove support for custom highlight names", "target Nvim 0.11, drop testing for 0.9.5"; v2.1.0 2026-03-26 | releases | Lock rev 31d6fb2d (2026-07-14) is post-v2.1.0, 3 behind main; verify `lua/pack/specs/opt/gitsigns.lua` sets no custom highlight names |
| `zbirenbaum/copilot.lua` | v2.0.0 (2026-03-06) BREAKING "remove nvim 0.10 support", "increase nodejs version requirement"; v3.0.0 (2026-06-11) BREAKING "remove support for apps.json"; README requires Neovim 0.11+, Node v22+ | releases; README | Lock rev d521d395 (2026-07-05) is post-v3.0.0, 8 behind master |
| `L3MON4D3/LuaSnip` | v2.5.0 (2026-04-05) "prompted by a fix to a breaking change in Neovim 0.12" (PR #1430 "fix `from_cursor_pos` for Neovim after fd1e019", merged 2026-03-21) | releases; PR | Lock rev 0abc8f39 = master head (includes fix). Spec's `luasnip.util.vimversion` cache patch (`lua/pack/specs/opt/luasnip.lua:10-16`) references issue #1393, closed 2025-10-14 — re-check whether the workaround is still needed |
| `saghen/blink.cmp` | v1.10.0 (2026-03-14): "fuzzy matching library no longer requires nightly"; latest tag v1.10.2 (2026-04-04); CHANGELOG top entry is still 1.10.0 | releases; CHANGELOG main | Lock rev 5aa67dac (2026-07-14) is 35 behind main; no v2 announced |
| `mason-org/mason.nvim` | v2.x line (v2.3.1 2026-06-11); README minimum Neovim ≥ 0.10.0 | releases; README | URL move only (§2.2); lock rev = main head |
| `nvim-mini/mini.nvim` | v0.18.0 (2026-06-21): "Soft deprecate support for Neovim 0.9", "Development of 'mini.deps' is frozen in favor of … vim.pack", adds `restart()` for Neovim ≥ 0.12 | release notes | URL move (§2.2); lock 33 behind main; spec uses only `mini.trailspace` |
| `Bekaboo/dropbar.nvim` | README requires Neovim ≥ 0.11.0; README already documents the `BufModifiedSet` → `OptionSet` swap; master still calls `vim.F.npcall` (deprecated 0.13, removed 0.15) at `lua/dropbar/sources/treesitter.lua:176`; no open issue mentions `npcall` (search returned only a release chore) | README; file on master; `:checkhealth vim.deprecated` | Lock rev = master head. Works today; expect a deprecation warning until upstream migrates. Note the config also carries a local `lua/plugin/winbar/` fork (disabled) with the same two problems |
| `DrKJeff16/project.nvim` | README requires Neovim ≥ v0.11; releases every few weeks (v6.1.0-1 2026-08-30); v6.0.0-1 notes list only a bug fix | README; releases | Lock rev 61ccbbf3 — `UNVERIFIED` distance from main; review `setup()` options on next update |
| `OXY2DEV/markview.nvim` | v28.0.0 (2025-12-23) BREAKING "Dropped backwards compatibility for versions lower than v25.0.0"; README requires Neovim ≥ 0.10.3 | releases; README | Lock rev 2471f409 — `UNVERIFIED` whether it is ≥ v28 |
| `folke/sidekick.nvim` | v2.0.0 (2025-10-17) BREAKING "changed the default keymaps"; README requires Neovim ≥ 0.11.2 and `nvim-treesitter-textobjects` `main` (optional) | releases; README | Spec sets `enabled = false` (inert in wrapper) and its own keymaps |
| `folke/noice.nvim` | README: Neovim ≥ 0.9, "nightly highly recommended"; last release v4.10.0 (2025-02-06); last push 2025-11-03; open issue #1201 "Doesn't hide cmdline (cmdheight = 0) with ui2" | README; releases; issue search | Neovim 0.12 `ui2` is experimental and off by default (`news12` UI). Spec sets `enabled = false` (inert). `UNVERIFIED` full compatibility with 0.13 message events (`msg_show.progress`, `news13` EVENTS) |
| `neogit` / `diffview` / `triptych` / `nvterm` specs | Use lazy.nvim fields `dependencies`, `branch`, `enabled` in `data` | `lua/utils/pack.lua` handles only `data.deps`/`data.exts` (lines 130-135, 261-270); no `enabled`/`branch` handling | Convert `dependencies` → `deps`, drop `branch` (neogit default branch is already `master`), decide what `enabled = false` should do (7 specs: fluoride, noice, nvterm, sidekick, termite, themeswitcher, which-key) |

### 2.4 Plugins fine as-is

Not archived, default branch unchanged, README minimum ≤ 0.12, no breaking
release since Feb 2026 found in release notes. `pushed_at` from GitHub API.

| Plugin | Default branch | Last push | README minimum Neovim | Notes |
|---|---|---|---|---|
| altermo/ultimate-autopair.nvim | `v0.6` | 2026-07-18 | 0.9 | README "Ultimate-autopair.nvim 0.6.1" |
| barrettruth/canola.nvim | main | 2026-07-20 | 0.10+ | "Drop-in replacement" for oil.nvim, "same module, same config, same `require('oil').setup(opts)`"; spec `start/oil.lua` already uses it |
| bassamsdata/namu.nvim | main | 2026-02-17 | not stated (`UNVERIFIED`) | last release v0.6.0 2025-06-22 |
| benlubas/molten-nvim | main | 2026-07-03 | not stated | v1.9.2 2025-01-28; needs Python provider (disabled here: `loaded_python3_provider=0` per checkhealth) — `UNVERIFIED` whether molten currently works |
| chrisgrieser/nvim-early-retirement | main | 2026-08-03 | 0.10 (for one option) | |
| chrisgrieser/nvim-spider | main | 2026-08-03 | not stated | |
| dgagn/diagflow.nvim | main | 2025-03-04 | not stated | stale; no built-in equivalent for top-right float |
| dhruvasagar/vim-table-mode | master | 2025-11-22 | Vimscript | |
| dnlhc/glance.nvim | master | 2026-09-03 | 0.9 (0.10 for one option) | |
| Eandrju/cellular-automaton.nvim | main | 2025-01-31 | 0.9 | spec references PR #37 "fix: prevent window jumping when host window has winbar" — still open, unmerged |
| fei6409/log-highlight.nvim | main | 2026-05-06 | not stated | |
| flwyd/vim-conjoin | master | 2025-06-09 | Vimscript | |
| folke/flash.nvim | main | 2026-08-22 | 0.8 | last tag v2.1.0 2024-07 |
| folke/lazydev.nvim | main | 2026-03-14 | 0.10 | v1.10.0 2025-10-23 |
| folke/todo-comments.nvim | main | 2025-11-10 | 0.8 | v1.5.0 2025-11-10 |
| folke/which-key.nvim | main | 2025-10-28 | 0.9.4 | v3.17.0 2025-02-22; spec `enabled=false` (inert) |
| HakonHarnes/img-clip.nvim | main | 2026-09-02 | not stated | v0.6.0 2025-02-23 |
| iamcco/markdown-preview.nvim | master | 2024-07-23 | not stated | stale 2 years; needs Node (`neovim` npm package missing per checkhealth, but the plugin runs its own server) |
| ibhagwan/fzf-lua | main | 2026-09-01 | 0.9 (badge) | `utils.lua:1833` already does `vim.npcall or vim.F.npcall`; lock 13 behind |
| jbyuki/one-small-step-for-vimkind | main | 2026-01-12 | not stated | |
| jmbuhr/otter.nvim | main | 2026-07-08 | 0.10 | v2.14.6 2026-07-08; README marks `buffers.set_filetype` as deprecated |
| junegunn/vim-easy-align | master | 2024-07-23 | Vimscript | |
| karb94/neoscroll.nvim | master | 2025-12-31 | 0.5 | |
| kevinhwang91/nvim-bqf | main | 2026-04-02 | 0.6.1 | |
| L3MON4D3/LuaSnip | master | 2026-05-19 | 0.9 | see §2.3 |
| max397574/better-escape.nvim | master | 2026-04-22 | not stated | |
| mfussenegger/nvim-dap | master | 2026-09-02 | "Latest nightly, 0.12.x (Recommended), 0.11.7" | explicitly supports nightly |
| MunifTanjim/nui.nvim | main | 2026-08-22 | 0.5 | |
| nacro90/numb.nvim | master | 2026-08-03 | 0.10 | README documents `vim.pack` install |
| navarasu/onedark.nvim | master | 2026-04-13 | 0.9 | local checkout ahead of lock (§3.4) |
| NeogitOrg/neogit | master | 2026-08-22 | 0.10 (badge) | spec `branch="master"` inert but harmless |
| niuiic/blink-cmp-rg.nvim | main | 2024-12-11 | not stated | stale; `UNVERIFIED` against blink.cmp 1.10 source API |
| nvim-neotest/nvim-nio | master | 2026-07-15 | not stated | |
| nvim-treesitter/nvim-treesitter-context | master | 2026-08-02 | 0.9 | v1.0.0 2025-05-29; uses `vim.treesitter`, no dependency on nvim-treesitter `configs` |
| rcarriga/nvim-dap-ui | master | 2026-07-14 | not stated | v4.0.0 2024-03 |
| RRethy/nvim-treesitter-endwise | master | 2025-12-29 | not stated | Lua files contain no `require('nvim-treesitter.configs'|parsers|ts_utils)` — works without nvim-treesitter master |
| ruicsh/termite.nvim | main | 2026-05-02 | 0.7 | spec `enabled=false` (inert) |
| saghen/blink.cmp | main | 2026-09-02 | not stated in README (terminal completion "0.11+ only") | see §2.3 |
| Sang-it/fluoride | main | 2026-04-03 | 0.9 | spec `enabled=false` (inert) |
| scalameta/nvim-metals | main | 2026-07-02 | not stated in README (`UNVERIFIED`) | |
| simonmclean/triptych.nvim | main | 2026-04-14 | 0.9 | local checkout ahead of lock (§3.4) |
| sindrets/diffview.nvim | main | 2024-08-02 | not stated | no commits for 2 years; 0.12 `:DiffTool` covers directory/file diffs only |
| stevearc/conform.nvim | master | 2026-08-11 | 0.10 | v9.1.0 2025-08-22 |
| stevearc/oil.nvim | master | 2026-06-02 | 0.10 | v2.16.0 2026-05-24; not in specs (canola replaces it) |
| stevearc/quicker.nvim | master | 2026-05-24 | 0.10 | v1.5.1 2026-05-24 |
| sudo-tee/opencode.nvim | main | 2026-09-01 | not stated | |
| tpope/vim-dispatch | master | 2024-09-02 | Vimscript | |
| tpope/vim-fugitive | master | 2026-03-07 | Vimscript | local checkout differs from lock (§3.4) |
| tpope/vim-projectionist | master | 2024-12-21 | Vimscript | |
| tpope/vim-sleuth | master | 2024-09-19 | Vimscript | |
| tronikelis/ts-autotag.nvim | master | 2026-06-25 | not stated | uses treesitter only; README shows fallback to `vim.lsp.buf.rename()` |
| uhhuhuhuhuh/themeswitcher.nvim | main | 2026-04-19 | not stated | spec `enabled=false` (inert); local checkout differs from lock |
| vim-test/vim-test | master | 2026-06-02 | Vimscript | |
| Wansmer/treesj | main | 2026-05-28 | 0.9 | nvim-treesitter "optional: if you install parsers with nvim-treesitter" |
| WhoIsSethDaniel/mason-tool-installer.nvim | main | 2026-01-22 | 0.8 | dep URL must follow mason move |
| willothy/flatten.nvim | main | 2026-06-19 | 0.10 | |
| sainnhe/everforest | master | 2026-06-08 | Vimscript | |
| sainnhe/gruvbox-material | master | 2026-04-15 | Vimscript | local checkout differs from lock |
| kyazdani42 → nvim-tree/nvim-web-devicons | master | 2026-08-30 | 0.7 | URL move only |
| beauwilliams → nvim-focus/focus.nvim | master | 2026-02-08 | 0.9 | URL move only |
| echasnovski → nvim-mini/mini.ai | main | 2026-07-10 | recommends vim.pack on 0.12+ | URL move; `an`/`in` clash (§2.1) |
| catgoose/nvim-colorizer.lua | master | 2026-07-14 | 0.10 | URL move; document_color overlap (§2.1) |

---

## 3. Local checks (read-only)

### 3.1 Version

```
$ NVIM_APPNAME=nvim nvim --headless "+lua vim.print(vim.version())" +q
{ major = 0, minor = 13, patch = 0, prerelease = "dev", build = "Homebrew", api_level = 15, api_prerelease = true }
```

### 3.2 `:checkhealth` (`/tmp/nvim-checkhealth.txt`, 491 lines)

- `vim.deprecated` ⚠ 1: "vim.F.npcall is deprecated. Feature will be removed in
  Nvim 0.15" — traceback through `dropbar.nvim/lua/dropbar/sources/treesitter.lua:176`.
- `vim.health` ⚠ 1: "Build is outdated. Local: 4b69d3fd2d, HEAD: 5209695703db".
  `vim.ui.open` handler found (`open`); ripgrep/git/curl OK.
- `vim.lsp` ✅ (no active clients in headless).
- `vim.pack` ⚠ 14 ❌ 6:
  - ❌ "not at expected revision": `triptych.nvim`, `onedark.nvim`,
    `vim-fugitive`, `themeswitcher.nvim`, `termite.nvim`, `gruvbox-material`
    (advice: `vim.pack.update({name}, {offline = true})`).
  - ⚠ "not at state which is a result of `vim.pack` operation": termite,
    themeswitcher, todo-comments, triptych, ultimate-autopair, vim-conjoin,
    vim-dispatch, vim-easy-align, vim-fugitive, vim-projectionist, vim-rhubarb,
    vim-sleuth, vim-table-mode, volt.
  - Lockfile path `/Users/eddyekofo/.config/nvim/nvim-pack-lock.json`; plugin
    dir `~/.local/share/nvim/site/pack/core/opt` (87 directories).
- `vim.provider` ⚠ 4: node `neovim` package missing, perl missing, ruby host
  missing (python3 provider disabled by config).
- `vim.treesitter` ✅: ABI min 13 max 15; parsers from nvim-treesitter `main`
  install dir plus bundled `c/lua/markdown/markdown_inline/query/vim/vimdoc`.
- `vim.ui.img` ❌ "Graphics protocol: not supported by this terminal" (headless;
  interactive ghostty result `UNVERIFIED`).
- `fzf_lua` ⚠ 2: optional `viu`, `ueberzugpp` missing.

Startup: `nvim --headless +qa` with the config → `v:errmsg` empty;
with a file argument → `E31: No such mapping` (from `pcall(vim.api.nvim_del_keymap …)`
at `lua/utils/load.lua:366`, benign). `plugin/intro.lua` only runs with a UI and
no args (line 23), which is why the `BufModifiedSet` error does not show headless.

### 3.3 Headless API probe (`nvim --headless --clean -l /tmp/apicheck.lua`)

ABSENT on this build: `vim.tbl_islist`, `vim.tbl_add_reverse_lookup`,
`vim.lsp.buf_get_clients`, `vim.lsp.get_active_clients`, `vim.lsp.with`,
`vim.lsp.buf.completion`, `vim.lsp.buf.execute_command`,
`vim.lsp.util.jump_to_location`, `vim.lsp.util.get_progress_messages`,
`vim.lsp.util.parse_snippet`, `vim.diagnostic.disable`, `vim.diagnostic.is_disabled`,
`vim.treesitter.query.get_query`, `vim.async`, option `'previewpopup'`.

Present (new): `vim.hl.hl_op`, `vim.npcall`, `vim.nonnil`, `vim.isnil`,
`vim.text.diff`, `vim.lsp.inline_completion`, `vim.lsp.document_color`,
`vim.lsp.linked_editing_range`, `vim.lsp.on_type_formatting`, `vim.lsp.foldexpr`,
`vim.lsp.buf.selection_range`, `vim.lsp.buf.workspace_diagnostics`,
`vim.lsp.is_enabled`, `vim.lsp.get_configs`, `vim.diagnostic.jump/status`,
`vim.treesitter.select`, `vim.ui.img`, `vim.ui.progress_status`, `vim.net.request`,
`vim.log`, `vim.pos`, `vim.range`, `vim.pack.{add,update,del,get}`,
`nvim_win_resize`; options `winborder autocomplete pumborder packlockfile
scrolloffpad winpinned messagesopt pummaxwidth diffanchors chistory busy`.

Present but deprecated: `vim.highlight`, `vim.hl.on_yank` (warning emitted),
`vim.F.npcall`, `vim.tbl_flatten`, `vim.region`, `vim.loop`, `vim.diff`,
`vim.lsp.semantic_tokens.start/stop`, `vim.lsp.codelens.refresh/clear/display/save`,
`vim.lsp.start_client/stop_client/client_is_stopped/get_buffers_by_client_id/set_log_level/get_log_path`,
`vim.lsp.util.stylize_markdown/character_offset`, `vim.diagnostic.goto_next/prev`,
`vim.fn.ctxget`, `vim.fn.termopen`. Deprecated `buffer=` keys for keymaps and
autocmds still work with no warning.

### 3.4 Lockfile (`nvim-pack-lock.json`, 87 entries vs 77 spec files)

- Only two entries carry a `version`: `nvim-treesitter` `'main'`,
  `nvim-treesitter-textobjects` `'main'` (quotes are vim.pack serialisation).
  Both branches exist upstream (`main` heads 2026-09-01 / 2026-09-03);
  `master` also still exists on both but is locked (nvim-treesitter) or stale
  (textobjects master 2025-10-31).
- No lock entry pins a branch that no longer exists. `neogit` `nightly` branch
  (2024-05-19) is not referenced.
- On-disk vs lock (local HEAD dates): triptych 295df974 (2026-04-14) vs lock
  18746e1; onedark df4792ac (04-13) vs 213c23a; vim-fugitive 3b753cf8 (03-07) vs
  61b51c0; themeswitcher 54b49a8d (04-19) vs 9d68214; termite d9bb384d (05-02)
  vs 60184a1; gruvbox-material 11d779b2 (04-15) vs 790afe9.
- Stale relative to upstream (lock rev date → behind default branch):
  nvim-treesitter 2026-04-03 (47), blink.cmp 2026-07-14 (35), mini.nvim
  2026-07-14 (33), fzf-lua 2026-07-08 (13), copilot.lua 2026-07-05 (8),
  vimtex 2026-07-05 (53), textobjects 2026-04-07 (4), gitsigns 2026-07-14 (3),
  web-devicons (3). Identical to head: LuaSnip, nvim-surround, dropbar, mason,
  colorizer, focus, noice.
- Lock entries with no spec (orphans): `lsp-timeout.nvim`, `nvim-lspconfig`,
  `smart-motion.nvim`, `snacks.nvim`, `volt`, `mini.icons`. Legitimate
  dependency-only entries: `plenary.nvim` (opencode `deps`), `blink.lib`,
  `vim-rhubarb`, `fugitive-gitlab.vim`.
- Last lock commit: `5068ad0b 2026-07-15 Update Neovim and repair plugin compatibility`.

---

## 4. Unverified items

- Impact of the 0.13 `%=`-in-item-group change on `lua/plugin/statusline.lua`
  and `lua/plugin/statuscolumn.lua` (needs a visual check).
- Whether `noice.nvim` renders correctly on 0.13 message events (`msg_show.progress`),
  and its behaviour once `ui2` is enabled (issue #1201 open).
- `blink-cmp-rg.nvim` (last commit 2024-12) against blink.cmp 1.10 source API.
- Distance of `project.nvim`, `markview.nvim`, `namu.nvim`, `nvim-metals`
  lock revisions from their current heads, and their exact minimum Neovim
  where the README does not state one.
- Whether molten-nvim works with the Python provider disabled.
- Interactive `vim.ui.img` support under ghostty 1.3.1.
- Whether copilot.lua is still required to provision the Copilot language
  server when switching suggestions to `vim.lsp.inline_completion`.
- Runtime behaviour of the seven `enabled = false` specs (code shows the field is
  unhandled, but headless checkhealth cannot observe the deferred `UIEnter` load).
