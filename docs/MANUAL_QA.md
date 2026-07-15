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

Still worth confirming during normal service- and language-dependent use:

- Blink documentation and snippet-specific completion retain their expected key
  behavior during normal language-project use.
- Copilot suggestions appear and `<C-j>` accepts a suggestion.
- Fzf-lua register insertion retains the customized behavior.
- LSP attach, diagnostics, statusline, formatting, and hover work in a project.
- DAP and Molten operate against configured debuggers and kernels.
- Copilot, terminals, and the complete interaction set feel unchanged in normal
  use.

Record any failure in `bugs_fixes/ENGINEERING_LOG.md` before another repair loop.
