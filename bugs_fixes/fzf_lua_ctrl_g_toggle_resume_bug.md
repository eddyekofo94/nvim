# fzf-lua ctrl-g Toggle / Resume Bug

## Bug

In `lua/pack/specs/start/fzf-lua.lua`, `ctrl-g` toggles between file-like
pickers and grep correctly at first. After several back-and-forth toggles, the
picker exits unexpectedly and accepts/opens the current item.

After this happens, reopening the picker with resume (`<leader>'`) no longer
works reliably. The picker briefly opens and closes immediately, and the
terminal flashes:

```text
[Process exited 0]
```

## Relevant Locations

- `actions.toggle_files_grep()`:
  `lua/pack/specs/start/fzf-lua.lua`
- Toggle state:
  `_toggle_state`
- fzf window lifecycle:
  `winopts.on_create` and `winopts.on_close`
- Resume mapping:
  `<leader>'` calls `fzf.resume`

## Current Analysis

The config already defends against two known failure modes:

1. Stale normalized fzf-lua resume opts

   fzf-lua stores normalized picker options in `fzf.config.__resume_data`.
   Those opts can contain fields such as `_normalized`, `__call_opts`,
   `__call_fn`, and `__resume_key`. If those normalized opts are passed back
   into a picker, `config.normalize_opts` may short-circuit and skip merging
   setup-level actions. That can drop custom bindings such as:

   ```lua
   ["ctrl-g"] = actions.toggle_files_grep
   ```

   When that binding is missing, pressing `ctrl-g` can stop behaving like the
   custom toggle and the picker may fall through to an unintended close/open
   behavior.

2. Old picker cleanup racing the new picker

   `actions.toggle_files_grep()` launches the next picker from inside the
   current fzf action. The old picker then closes and runs `on_close`, which
   schedules delayed cleanup. If that delayed cleanup runs after the new picker
   has opened, it can clobber global fzf state such as:

   ```lua
   vim.g._fzf_active
   vim.g._fzf_win
   ```

   It can also trigger focus.nvim resize/focus restoration while the new fzf
   terminal is active. That may leave the new fzf terminal in a bad state where
   its bindings no longer apply.

The remaining bug is probably still in this boundary. The toggle relaunch uses
`vim.schedule()`, while fzf-lua is also updating resume data, closing the old
terminal job, and running scheduled/deferred `on_close` cleanup. After enough
switches, resume data or window state can point at a picker whose underlying fzf
process has already exited normally, which matches the visible
`[Process exited 0]` message.

## Proposed Fix Plan

1. Add temporary instrumentation around the toggle and window lifecycle.

   Log these values before and after every `ctrl-g` toggle, and in
   `on_create` / `on_close`:

   - `fzf.config.__resume_data.opts.__resume_key`
   - `fzf.config.__resume_data.opts._normalized`
   - `fzf.config.__resume_data.opts.__call_opts`
   - `fzf.config.__resume_data.opts.cmd`
   - whether `search_paths` exists
   - `vim.g._fzf_win`
   - `vim.g._fzf_active`
   - current window id and buffer filetype

2. Determine which failure path is happening.

   The key question is whether, at the moment it breaks:

   - the `ctrl-g` binding has disappeared because stale normalized opts were
     reused, or
   - the binding still exists but the fzf terminal/window state is already
     stale or clobbered by cleanup.

3. Replace direct scheduled relaunches with a transition helper.

   Instead of calling the next picker directly inside:

   ```lua
   vim.schedule(function()
     fzf.live_grep(grep_opts)
   end)
   ```

   introduce a helper that:

   - sets `vim.g._fzf_transitioning = true`
   - captures the closing fzf window id
   - waits until the old window is invalid/closed
   - launches the next picker
   - clears the transition flag from the new picker's `on_create`

4. Make `on_close` transition-aware.

   While `vim.g._fzf_transitioning` is true, `on_close` should avoid:

   - clearing `_fzf_active`
   - clearing `_fzf_win`
   - restoring focus to the previous editor window
   - running focus.nvim resize
   - reopening quickfix/location windows unless the transition completes

5. Add a safe resume wrapper.

   Replace the direct `<leader>'` mapping to `fzf.resume` with a local wrapper
   that sanitizes `fzf.config.__resume_data.opts` before resuming. If the last
   picker was part of the files/grep toggle flow and resume data is stale, fall
   back to reopening the last logical picker from `_toggle_state`.

6. Verify with repeated stress testing.

   Test these flows:

   - `smart_files -> ctrl-g -> ctrl-g`, repeated at least 20 times
   - accept an item after repeated toggles
   - reopen with `<leader>'`
   - repeat with `files`, `buffers`, `oldfiles`, and `args`

## Expected Outcome

`ctrl-g` should remain stable no matter how many times the picker switches
between files and grep. It should not accidentally accept/open an item, and
`<leader>'` should resume or safely reopen the last logical picker instead of
showing a dead terminal buffer with `[Process exited 0]`.
