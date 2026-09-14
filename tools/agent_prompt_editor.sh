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
TRANSCRIPT_READER=${AGENT_PROMPT_TRANSCRIPT_READER:-$HOME/.dotfiles/agent-config/claude/closeout_capture.py}

# Never inherit another launch's files: a stale closeout beside a fresh prompt
# is worse than no closeout at all.
unset AGENT_CLOSEOUT_FILE AGENT_PROMPT_SEED_FILE AGENT_PROMPT_REASON

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

# Codex 0.153.4 launches its external editor without a CODEX_* environment
# marker. Its prompt is nevertheless a tightly-scoped temporary Markdown file:
# `~/.codex/editor/.tmpXXXXXX.md`, with a six-character alphanumeric suffix.
# Keep this as a second, shape-based signal rather than broadening agent
# detection to every temporary file; ordinary editors still fall through.
codex_prompt_file() {
    [ "$#" -eq 1 ] || return 1
    editor_dir=${AGENT_PROMPT_CODEX_EDITOR_DIR:-$HOME/.codex/editor}
    [ "$(dirname -- "$1")" = "$editor_dir" ] || return 1
    [[ "${1##*/}" =~ ^\.tmp[[:alnum:]]{6}\.md$ ]]
}

# Only Claude Code writes ~/.claude/projects transcripts, and the reader falls
# back to the *project's* newest one when the pane carries no session id. In any
# other runtime that fallback is guaranteed to be some Claude pane's work, so
# the transcript is only ever consulted for a Claude pane.
launched_by_claude_code() {
    case "${AI_AGENT:-}" in
        claude*) return 0 ;;
    esac
    [ -n "${CLAUDECODE:-}" ] && return 0
    for name in $(compgen -e); do
        case $name in
            CLAUDE_CODE_*) [ -n "${!name}" ] && return 0 ;;
        esac
    done
    return 1
}

# Every failure below falls through to a plain editor, which on screen is
# indistinguishable from "the feature is broken". Point AGENT_PROMPT_DEBUG at a
# file and the shim records which precondition actually failed.
note() {
    # Always exported, so Neovim can say *why* rather than just "no closeout".
    # A reason the user can read beats one only a debug flag would have caught.
    export AGENT_PROMPT_REASON=$1
    # Logged unconditionally: gating this on a debug variable meant the sessions
    # that actually failed were the ones that recorded nothing. Tagged with the
    # Herdr session as well as the pane, since every window has a `w1:p2`.
    printf '%s [%s/%s] %s\n' "$(date +%H:%M:%S)" \
        "${HERDR_SESSION:-no-session}" "${HERDR_PANE_ID:-no-pane}" "$1" \
        >>"${AGENT_PROMPT_DEBUG:-/tmp/agent-prompt-debug.log}" 2>/dev/null || true
}

# The place this pane occupies across every Herdr session on the machine.
# `HERDR_PANE_ID` is only unique inside one session, and each independent
# Ghostty window is its own session sharing the same $TMPDIR, so the Herdr
# session is prefixed whenever it is known. Mirror of `place()` in
# agent-config/claude/closeout_capture.py: both derive the same name from the
# same environment, or the hook's record is invisible to this shim.
pane_place() {
    pane=$(printf '%s' "${HERDR_PANE_ID:-}" | tr -c '[:alnum:]._-' '_')
    if [ -n "${HERDR_SESSION:-}" ]; then
        printf '%s.%s' "$(printf '%s' "$HERDR_SESSION" | tr -c '[:alnum:]._-' '_')" "$pane"
    else
        printf '%s' "$pane"
    fi
}

# Which agent session this pane hosts. The environment is the cheap answer,
# but Claude Code does not hand CLAUDE_CODE_SESSION_ID to its $EDITOR, so in
# practice it is usually empty here. Herdr knows: the agent-state integration
# reports every Claude session to its pane on SessionStart, and `herdr pane
# get` returns it as `agent_session.value`. Asked of the pane itself, the
# answer cannot be a neighbour's. Empty when nobody can say.
agent_session_id() {
    if [ -n "${CLAUDE_CODE_SESSION_ID:-}" ]; then
        printf '%s' "$CLAUDE_CODE_SESSION_ID"
        return 0
    fi
    "$HERDR_BIN" pane get "${HERDR_PANE_ID:-}" 2>/dev/null | python3 -c '
import json, sys
try:
    session = json.load(sys.stdin)["result"]["pane"]["agent_session"]
    value = session["value"]
except (ValueError, KeyError, TypeError):
    sys.exit(1)
# The session object says whose id it is; the pane-level agent can lag it.
if session.get("agent") == "claude" and value:
    sys.stdout.write(value)
' 2>/dev/null || true
}

capture_closeout() {
    [ -n "${HERDR_PANE_ID:-}" ] || { note "no HERDR_PANE_ID; not in a Herdr pane"; return 1; }
    launched_by_agent || codex_prompt_file "$@" || {
        note "no agent marker or Codex prompt-file shape in env"
        return 1
    }
    [ -r "$READY_PROMPT" ] || { note "parser unreadable: $READY_PROMPT"; return 1; }
    command -v "$HERDR_BIN" >/dev/null 2>&1 || { note "herdr not on PATH: $HERDR_BIN"; return 1; }

    case "$CAPTURE_LINES" in
        ""|*[!0-9]*|0) note "bad CAPTURE_LINES: $CAPTURE_LINES"; return 1 ;;
    esac

    base=${TMPDIR:-/tmp}
    [ -d "$base" ] || { note "no temp dir: $base"; return 1; }
    # Pane ids carry `:`; keep the slug filesystem-safe and scoped to this
    # Herdr session *and* pane so concurrent agents -- in one window or across
    # windows -- never read each other's closeout.
    slug=$(pane_place)
    capture_file=$base/agent-prompt-capture.$slug.txt
    closeout_file=$base/agent-prompt-closeout.$slug.md
    seed_file=$base/agent-prompt-seed.$slug.txt

    rm -f -- "$closeout_file" "$seed_file"

    # Best source: the agent's own end-of-turn record -- the whole final
    # message, closeout included -- written by the Stop hook under this place's
    # slug *and* its session id. The place keeps two agents side by side -- or
    # in two windows -- apart; the session keeps a finished agent from handing
    # its message to whoever inherits the pane id next.
    turn_file=
    session_id=$(agent_session_id)
    if [ -n "$session_id" ]; then
        # Knowing the session, accept nothing else. A record under this place's
        # slug but another session id belongs to the pane's previous occupant,
        # which is precisely what must not be shown.
        session_slug=$(printf '%s' "$session_id" | tr -c '[:alnum:]._-' '_')
        candidate=$base/agent-prompt-turn-closeout.$slug.$session_slug.md
        [ -s "$candidate" ] && turn_file=$candidate
    else
        # Neither the environment nor Herdr names the session. Fall back to the
        # newest record for this place: the Stop hook drops the others when it
        # claims the pane, and SessionEnd removes its own, so what remains is
        # the live session's. The place carries the Herdr session, so another
        # window's agent at the same pane id is never a candidate.
        for candidate in "$base/agent-prompt-turn-closeout.$slug."*.md; do
            [ -s "$candidate" ] || continue
            [ -z "$turn_file" ] || [ "$candidate" -nt "$turn_file" ] || continue
            turn_file=$candidate
        done
    fi

    # Fallback: the agent's transcript on disk, which also covers sessions
    # predating the Stop hook. It is keyed on cwd and can resolve to the whole
    # project's newest transcript, so it gets its own pane-scoped file --
    # writing it into $turn_file would let one pane's project-wide match
    # overwrite another pane's own recorded closeout.
    transcript_file=$base/agent-prompt-transcript.$slug.md
    rm -f -- "$transcript_file"

    source_file=
    if [ -n "$turn_file" ]; then
        note "using this session's own recorded closeout"
        source_file=$turn_file
    elif ! launched_by_claude_code; then
        note "no recorded closeout for $HERDR_PANE_ID, and transcripts are Claude-only"
    elif [ ! -r "$TRANSCRIPT_READER" ]; then
        note "transcript reader unreadable: $TRANSCRIPT_READER"
    else
        # With a session id the reader opens that transcript and no other; a
        # fresh session with no closeout yet reads as none, never as the
        # neighbour's. Only when nobody can name the session does it fall back
        # to the project's newest transcript, keyed on this pane's cwd.
        reader_err=$(python3 "$TRANSCRIPT_READER" --print \
            "$session_id" "$PWD" 2>&1 >"$transcript_file")
        if [ -s "$transcript_file" ]; then
            note "using the agent's transcript"
            source_file=$transcript_file
        else
            note "transcript had no closeout${reader_err:+: $reader_err}"
            rm -f -- "$transcript_file"
        fi
    fi

    if [ -n "$source_file" ]; then
        export AGENT_CLOSEOUT_FILE=$source_file
        if bash "$READY_PROMPT" --extract "$source_file" \
            >"$seed_file" 2>/dev/null && [ -s "$seed_file" ]; then
            export AGENT_PROMPT_SEED_FILE=$seed_file
        else
            rm -f -- "$seed_file"
        fi
        return 0
    fi

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
capture_closeout "$@" || true

# Neovim resolves relative paths against its working directory, and `uv.cwd()`
# fails outright once that directory is deleted underneath the pane -- a swept
# worktree is the usual way. Every `vim.fs.find`/`vim.fs.root` call that takes
# no explicit path then throws, on *every* autocmd: session autosave and the
# Copilot root lookup both fire on InsertEnter, so the editor is unusable. Land
# somewhere that exists instead; a wrong-but-live cwd beats a dead one.
if ! pwd -P >/dev/null 2>&1; then
    note "working directory is gone; starting Neovim in $HOME"
    cd -- "$HOME" || true
fi

exec "$NVIM_BIN" "$@"
