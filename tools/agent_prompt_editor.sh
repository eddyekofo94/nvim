#!/usr/bin/env bash

# $EDITOR/$VISUAL shim for agent prompt editing.
#
# An agent's ctrl+g hands its prompt to $EDITOR. Neovim takes the pane's
# alternate screen before any of its own startup code runs, and `herdr pane
# read` then reports that alternate screen instead of the scrollback — every
# source returns the Neovim window, not the closeout. So the capture has to
# happen here, in the moment between the agent releasing the pane and Neovim
# claiming it.
#
# Everything below is best-effort. Any failure leaves AGENT_CLOSEOUT_FILE unset
# and falls through to a plain `nvim "$@"`, which is also what an ordinary
# `git commit` or `fc` gets when it reaches this shim.

set -u

NVIM_BIN=${AGENT_PROMPT_NVIM:-nvim}
HERDR_BIN=${AGENT_PROMPT_HERDR:-herdr}
READY_PROMPT=${AGENT_PROMPT_READY_PROMPT:-$HOME/.dotfiles/herdr/prototype/ready_prompt_parser.sh}
CAPTURE_LINES=${AGENT_PROMPT_CAPTURE_LINES:-2000}

# Never inherit another launch's files: a stale closeout beside a fresh prompt
# is worse than no closeout at all.
unset AGENT_CLOSEOUT_FILE AGENT_PROMPT_SEED_FILE

# Mirror of `agent_env` / `agent_env_prefixes` in lua/plugin/agent-prompt.lua.
# `AI_AGENT` is the cross-vendor convention but only Claude Code writes it, so
# gating on it alone would make this a Claude-only feature.
AGENT_MARKERS="AI_AGENT CLAUDECODE OPENCODE CURSOR_AGENT GEMINI_CLI"
AGENT_MARKER_PREFIXES="CLAUDE_CODE_ CODEX_ OPENCODE_ PI_CODING_AGENT PI_PILOT_ AIDER_"

launched_by_agent() {
    for name in $AGENT_MARKERS; do
        [ -n "${!name:-}" ] && return 0
    done
    for name in $(compgen -e); do
        for prefix in $AGENT_MARKER_PREFIXES; do
            case $name in
                "$prefix"*) [ -n "${!name}" ] && return 0 ;;
            esac
        done
    done
    return 1
}

# Every failure below falls through to a plain editor, which on screen is
# indistinguishable from "the feature is broken". Point AGENT_PROMPT_DEBUG at a
# file and the shim records which precondition actually failed.
note() {
    [ -n "${AGENT_PROMPT_DEBUG:-}" ] || return 0
    printf '%s %s\n' "$(date +%H:%M:%S)" "$1" >>"$AGENT_PROMPT_DEBUG" 2>/dev/null || true
}

capture_closeout() {
    [ -n "${HERDR_PANE_ID:-}" ] || { note "no HERDR_PANE_ID; not in a Herdr pane"; return 1; }
    launched_by_agent || { note "no agent marker in env"; return 1; }
    [ -r "$READY_PROMPT" ] || { note "parser unreadable: $READY_PROMPT"; return 1; }
    command -v "$HERDR_BIN" >/dev/null 2>&1 || { note "herdr not on PATH: $HERDR_BIN"; return 1; }

    case "$CAPTURE_LINES" in
        ""|*[!0-9]*|0) note "bad CAPTURE_LINES: $CAPTURE_LINES"; return 1 ;;
    esac

    base=${TMPDIR:-/tmp}
    [ -d "$base" ] || { note "no temp dir: $base"; return 1; }
    # Pane ids carry `:`; keep the slug filesystem-safe and pane-scoped so
    # concurrent agents never read each other's closeout.
    slug=$(printf '%s' "$HERDR_PANE_ID" | tr -c '[:alnum:]._-' '_')
    capture_file=$base/agent-prompt-capture.$slug.txt
    closeout_file=$base/agent-prompt-closeout.$slug.md
    seed_file=$base/agent-prompt-seed.$slug.txt

    rm -f -- "$closeout_file" "$seed_file"

    if ! "$HERDR_BIN" pane read "$HERDR_PANE_ID" \
        --source recent-unwrapped --lines "$CAPTURE_LINES" \
        >"$capture_file" 2>/dev/null; then
        note "herdr pane read failed for $HERDR_PANE_ID"
        rm -f -- "$capture_file"
        return 1
    fi

    if ! bash "$READY_PROMPT" --extract-closeout "$capture_file" \
        >"$closeout_file" 2>/dev/null || [ ! -s "$closeout_file" ]; then
        note "no closeout in the last $CAPTURE_LINES lines of scrollback"
        rm -f -- "$capture_file" "$closeout_file"
        return 1
    fi
    note "captured closeout: $closeout_file"
    export AGENT_CLOSEOUT_FILE=$closeout_file

    # The seed is optional: detection keys on the closeout alone, and a prompt
    # buffer with no seed simply stays empty.
    if bash "$READY_PROMPT" --extract "$capture_file" \
        >"$seed_file" 2>/dev/null && [ -s "$seed_file" ]; then
        export AGENT_PROMPT_SEED_FILE=$seed_file
    else
        rm -f -- "$seed_file"
    fi

    rm -f -- "$capture_file"
    return 0
}

# The closeout is verbatim agent output; keep it readable only by its author.
umask 077
capture_closeout || true

exec "$NVIM_BIN" "$@"
