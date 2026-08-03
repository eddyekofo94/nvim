#!/usr/bin/env bash

# The shim runs before Neovim exists, so nothing inside Neovim can cover it.
# Stub `herdr` and `nvim` and assert what the real Neovim would inherit.

set -u

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
shim=$repo/tools/agent_prompt_editor.sh
fixture=$repo/tests/fixtures/closeout_capture.txt
empty_fixture=$repo/tests/fixtures/no_closeout_capture.txt
ready_prompt=${AGENT_PROMPT_READY_PROMPT:-$HOME/.dotfiles/herdr/prototype/ready_prompt_parser.sh}

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/agent-prompt-editor.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

passed=0
failed=0

pass() {
  passed=$((passed + 1))
  printf 'ok %d - %s\n' "$passed" "$1"
}

fail() {
  failed=$((failed + 1))
  printf 'not ok - %s\n' "$1" >&2
}

if [ ! -r "$ready_prompt" ]; then
  printf 'ready_prompt.sh is unreadable at %s\n' "$ready_prompt" >&2
  exit 1
fi

mkdir -p "$tmpdir/bin"

# `nvim` stub: record the environment the real editor would have started with.
cat >"$tmpdir/bin/nvim" <<'STUB'
#!/bin/sh
{
  printf 'CLOSEOUT=%s\n' "${AGENT_CLOSEOUT_FILE:-}"
  printf 'SEED=%s\n' "${AGENT_PROMPT_SEED_FILE:-}"
  printf 'ARGS=%s\n' "$*"
} >"$STUB_ENV_OUT"
STUB
chmod +x "$tmpdir/bin/nvim"

# `herdr` stub: `pane read` emits whichever capture the case selected.
cat >"$tmpdir/bin/herdr" <<'STUB'
#!/bin/sh
[ "${1:-}" = pane ] || exit 2
[ "${2:-}" = read ] || exit 2
[ -n "${STUB_CAPTURE:-}" ] || exit 3
[ "${STUB_HERDR_FAIL:-0}" = 1 ] && exit 4
cat "$STUB_CAPTURE"
STUB
chmod +x "$tmpdir/bin/herdr"

run_shim() {
  case_name=$1
  shift
  out=$tmpdir/$case_name.env
  rm -f "$out"
  # This suite usually runs inside a real agent pane, whose HERDR_PANE_ID and
  # AI_AGENT would otherwise leak into the negative cases and make them pass
  # for the wrong reason.
  env -u HERDR_PANE_ID -u AI_AGENT \
    -u AGENT_CLOSEOUT_FILE -u AGENT_PROMPT_SEED_FILE \
    PATH="$tmpdir/bin:$PATH" \
    TMPDIR="$tmpdir" \
    STUB_ENV_OUT="$out" \
    AGENT_PROMPT_NVIM="$tmpdir/bin/nvim" \
    AGENT_PROMPT_HERDR="$tmpdir/bin/herdr" \
    AGENT_PROMPT_READY_PROMPT="$ready_prompt" \
    "$@" bash "$shim" "$tmpdir/prompt-$case_name.md"
  printf '%s' "$out"
}

field() {
  awk -F= -v key="$2" '$1 == key { print substr($0, length(key) + 2) }' "$1"
}

# --- a real agent launch ----------------------------------------------------
out=$(run_shim agent \
  HERDR_PANE_ID=w4:p2 AI_AGENT=claude-code_2-1_agent STUB_CAPTURE="$fixture")
closeout=$(field "$out" CLOSEOUT)
seed=$(field "$out" SEED)

if [ -n "$closeout" ] && [ -s "$closeout" ] && \
    grep -q 'Status.*DONE — newer run' "$closeout" && \
    grep -q 'NEWER PROMPT BODY LINE TWO' "$closeout" && \
    ! grep -q 'OLDER' "$closeout"; then
  pass 'agent launch exports the newest whole closeout'
else
  fail "agent launch exported no usable closeout (path [$closeout])"
fi

if [ -n "$seed" ] && grep -q 'NEWER PROMPT BODY LINE ONE' "$seed" && \
    ! grep -q 'Status' "$seed"; then
  pass 'agent launch exports the ready-to-paste block as the seed'
else
  fail "agent launch exported no usable seed (path [$seed])"
fi

if [ "$(field "$out" ARGS)" = "$tmpdir/prompt-agent.md" ]; then
  pass 'the prompt file reaches Neovim unchanged'
else
  fail "arguments were rewritten: $(field "$out" ARGS)"
fi

case "$closeout" in
  "$tmpdir"/*) pass 'the closeout is written under $TMPDIR' ;;
  *) fail "closeout escaped \$TMPDIR: $closeout" ;;
esac

mode=$(ls -l "$closeout" | cut -c1-10)
if [ "$mode" = "-rw-------" ]; then
  pass 'the closeout is readable only by its author'
else
  fail "closeout permissions are $mode"
fi

# --- everything that must fall through to plain nvim ------------------------
assert_bare() {
  name=$1
  out=$2
  if [ -z "$(field "$out" CLOSEOUT)" ] && [ -z "$(field "$out" SEED)" ]; then
    pass "$name"
  else
    fail "$name (closeout [$(field "$out" CLOSEOUT)])"
  fi
}

assert_bare 'no HERDR_PANE_ID falls through to plain nvim' \
  "$(run_shim nopane AI_AGENT=claude STUB_CAPTURE="$fixture")"

assert_bare 'no AI_AGENT falls through to plain nvim' \
  "$(run_shim noagent HERDR_PANE_ID=w4:p2 STUB_CAPTURE="$fixture")"

assert_bare 'a failing pane read falls through to plain nvim' \
  "$(run_shim herdrfail HERDR_PANE_ID=w4:p2 AI_AGENT=claude \
    STUB_CAPTURE="$fixture" STUB_HERDR_FAIL=1)"

assert_bare 'a capture with no closeout falls through to plain nvim' \
  "$(run_shim nocloseout HERDR_PANE_ID=w4:p2 AI_AGENT=claude \
    STUB_CAPTURE="$empty_fixture")"

# A stale variable from an earlier launch must never survive into a session
# whose own capture failed.
assert_bare 'an inherited AGENT_CLOSEOUT_FILE is cleared when capture fails' \
  "$(run_shim inherited AI_AGENT=claude STUB_CAPTURE="$fixture" \
    AGENT_CLOSEOUT_FILE=/nonexistent/stale.md \
    AGENT_PROMPT_SEED_FILE=/nonexistent/stale.txt)"

printf '1..%d\n' "$((passed + failed))"
if [ "$failed" -ne 0 ]; then
  printf '%d test(s) failed\n' "$failed" >&2
  exit 1
fi
printf 'Agent prompt editor shim test passed.\n'
