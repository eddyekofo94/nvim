# Neovim workflow loops

## Upgrade loop

Trigger: Neovim HEAD or plugin revisions are being refreshed.

Stop condition: the requested Neovim revision is recorded in
`nvim-version.txt`, all managed plugins are at valid clean revisions, and
`tools/verify.sh` passes.

1. Record `git status --short` and preserve existing user changes.
2. Rebuild Neovim HEAD and update plugins through `vim.pack`.
3. Confirm shell-launched and clean-environment Neovim resolve to the same real
   data root; GUI launches may not inherit shell XDG variables.
4. Run `tools/verify.sh` after each compatibility repair.
5. Run `make format-check` and `make lint`; record baseline failures separately
   from failures introduced by the upgrade.
6. Complete `docs/MANUAL_QA.md` in an interactive Neovim session.

## Bug loop

Build a headless reproduction that matches the reported error, make it fail,
fix one cause, and add the scenario to `tools/verify.sh`. Do not rely on the
Neovim process exit code alone because autocmd errors may still exit with zero.

## Human handoff

Automated checks prove startup and integration invariants. The user confirms
interactive layout, keymaps, completion, picker behavior, and visual quality.
