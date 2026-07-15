# Code review - trigger-accurate lazy loading and Copilot lifecycle

Fixed point: `b69a80797c59a458efc399d0a5a7696f0256a4b0` (`HEAD`)

Fidelity source: the user's TDD repair request for the custom `vim.pack`
loader, Sidekick/Copilot lifecycle, three precedence bugs, formatting, stale
artifact cleanup, orphan-process cleanup, and required stop gates.

Standards sources: `AGENTS.md`, `docs/WORKFLOW_LOOPS.md`, `.stylua.toml`,
`docs/MANUAL_QA.md`, and the engineering log.

Mechanical separation: comparison against a StyLua-formatted `HEAD` found 443
tracked Lua files with formatting-only changes, 17 tracked Lua files with
semantic changes, and two new Lua regression-test files. The earlier informal
count of 18 semantic Lua files was an off-by-one inventory count.

## Standards

Four findings were found and fixed:

1. The process harness matched every Copilot server, not specifically orphaned
   post-exit servers. It now requires `PPID == 1`, revalidates identity before
   cleanup, and reports rapid and active lifecycle cases separately.
2. `AGENTS.md` still demonstrated single quotes and an unsupported `ft` field
   despite the selected StyLua policy and loader API. The guide and StyLua
   config now agree on double quotes and parenthesized calls, and the stale
   trigger example is removed.
3. Copilot exit cleanup used unchecked module and client calls. The exit path
   now follows the project's `pcall` rule while preserving forced shutdown.
4. The Homebrew PATH check used substring matching, the loader condition relied
   on implicit operator precedence, and `collect_specs()` returned an imprecise
   type. These are now entry-aware, parenthesized, and accurately annotated.

Post-fix Standards findings: 0.

## Fidelity

Five findings were found and fixed:

1. The lifecycle test could pass after package setup without proving an active
   Copilot client. It now runs both the scheduled-startup race and an active
   initialized-client case with the real `<C-j>` buffer mapping.
2. The regression covered only three Sidekick mappings and the existence of the
   Copilot command. It now verifies every configured Sidekick normal/visual
   mapping, NES/mux settings, Copilot suggestion keys, Markdown support, and the
   shell secret-file exclusion.
3. The UIEnter regression checked only `package.loaded`. It now also proves
   Mason and Copilot were not added to `runtimepath`.
4. Removed legacy stores and tracked debris were documented but not guarded.
   `tools/verify.sh` now fails if `data/lazy`, `data/packages`, `*.bak`, or
   `*.pyc` return.
5. The engineering log said every opt spec loads only from an explicit trigger,
   while intentionally non-lazy opt specs still load when the opt set is
   registered. The loader contract and documentation now state that distinction
   precisely.

Post-fix Fidelity findings: 0.

## Summary

Standards findings: 4 fixed, 0 unresolved. Fidelity findings: 5 fixed, 0
unresolved. The worst Standards issue was process-test scope; the worst Fidelity
issue was a potentially vacuous lifecycle test. Both review axes were rerun
after the fixes.

Verification passed: `tools/verify.sh`, `make lint` (473 files, zero findings),
`make format-check`, three additional rapid-plus-active Copilot lifecycle runs,
inherited and clean-environment startup, all-Lua syntax loading, shell syntax,
`git diff --check`, legacy-store/debris checks, and an exact final Copilot orphan
count of zero.
