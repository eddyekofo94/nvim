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
  printf 'PWD=%s\n' "$(pwd -P 2>/dev/null || printf '<gone>')"
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
  # agent markers would otherwise leak into the negative cases and make them
  # pass for the wrong reason. The markers are whatever the *host* agent
  # exports, so the unset list is computed rather than spelled out.
  unsets=$(env | sed -n -E \
    's/^(AI_AGENT|CLAUDECODE|OPENCODE|CURSOR_AGENT|GEMINI_CLI|CLAUDE_CODE_[A-Za-z0-9_]*|CODEX_[A-Za-z0-9_]*|OPENCODE_[A-Za-z0-9_]*|PI_CODING_AGENT[A-Za-z0-9_]*|PI_PILOT_[A-Za-z0-9_]*|AIDER_[A-Za-z0-9_]*)=.*/-u \1/p')
  # shellcheck disable=SC2086 # the unset list is deliberately word-split
  env $unsets -u HERDR_PANE_ID \
    -u AGENT_CLOSEOUT_FILE -u AGENT_PROMPT_SEED_FILE \
    PATH="$tmpdir/bin:$PATH" \
    TMPDIR="$tmpdir" \
    STUB_ENV_OUT="$out" \
    AGENT_PROMPT_NVIM="$tmpdir/bin/nvim" \
    AGENT_PROMPT_HERDR="$tmpdir/bin/herdr" \
    AGENT_PROMPT_READY_PROMPT="$ready_prompt" \
    AGENT_PROMPT_TRANSCRIPT_READER="${STUB_TRANSCRIPT_READER:-$tmpdir/missing-reader.py}" \
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

# --- the same launch under the other agent runtimes -------------------------
# Only Claude Code exports AI_AGENT, so each of these has to be recognised on
# its own marker or the feature would never fire outside Claude.
for marker in OPENCODE=1 CODEX_THREAD_ID=0199abcd PI_CODING_AGENT_DIR=/tmp/pi \
    CLAUDE_CODE_ENTRYPOINT=cli CURSOR_AGENT=1 AIDER_MODEL=gpt; do
  name=${marker%%=*}
  out=$(run_shim "marker-$name" HERDR_PANE_ID=w4:p2 "$marker" \
    STUB_CAPTURE="$fixture")
  if [ -s "$(field "$out" CLOSEOUT)" ]; then
    pass "$name alone identifies an agent launch"
  else
    fail "$name did not register as an agent launch"
  fi
done

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

assert_bare 'no agent marker at all falls through to plain nvim' \
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

# --- source precedence: pane record, then transcript, then scrape -----------
# The Stop hook writes a closeout under the pane's own slug. The transcript
# reader is keyed on cwd and falls back to the *project's* newest transcript
# whenever the pane carries no session id -- so it is the weaker source, and it
# must never be written into the pane-scoped file.
reader="$tmpdir/bin/reader.py"
cat >"$reader" <<'PY'
import sys
sys.stdout.write("**Status:** DONE\n**Next move:** from the PROJECT transcript\n")
PY

turn_file() {
  printf '%s/agent-prompt-turn-closeout.%s.%s.md' "$tmpdir" "$1" "$2"
}

# Two Claude panes in one repository. Both resolve to the same project
# transcript; each must still be shown the closeout its own turn recorded.
printf '**Status:** DONE\n**Next move:** pane one work\n' >"$(turn_file w1_p1 sessA)"
printf '**Status:** DONE\n**Next move:** pane two work\n' >"$(turn_file w1_p2 sessB)"

for pane in 'w1:p1|w1_p1|sessA|pane one work' 'w1:p2|w1_p2|sessB|pane two work'; do
  id=${pane%%|*}
  rest=${pane#*|}
  slug=${rest%%|*}
  rest=${rest#*|}
  session=${rest%%|*}
  want=${rest#*|}
  out=$(STUB_TRANSCRIPT_READER="$reader" run_shim "twopane-$slug" \
    HERDR_PANE_ID="$id" AI_AGENT=claude CLAUDE_CODE_SESSION_ID="$session" \
    STUB_CAPTURE=/nonexistent)
  got=$(field "$out" CLOSEOUT)
  if [ -n "$got" ] && grep -q "$want" "$got" 2>/dev/null && \
      ! grep -q 'PROJECT transcript' "$got" 2>/dev/null; then
    pass "$id is shown its own recorded closeout, not the project transcript"
  else
    fail "$id was shown [$(cat "$got" 2>/dev/null)]"
  fi
  if grep -q "$want" "$(turn_file "$slug" "$session")"; then
    pass "$id's recorded closeout survives the run"
  else
    fail "$id's recorded closeout was overwritten"
  fi
done

# --- a reused pane id -------------------------------------------------------
# The exact failure Eddy hit: a pane whose previous occupant left a record. A
# session that knows its own id must never accept another session's file, even
# in its own pane. Nothing recorded yet means the transcript, then the scrape.
printf '**Status:** DONE\n**Next move:** the DEAD session\n' >"$(turn_file w7_p7 old)"
out=$(STUB_TRANSCRIPT_READER="$reader" run_shim reused \
  HERDR_PANE_ID=w7:p7 AI_AGENT=claude CLAUDE_CODE_SESSION_ID=new \
  STUB_CAPTURE=/nonexistent)
got=$(field "$out" CLOSEOUT)
if [ -n "$got" ] && ! grep -q 'DEAD session' "$got" 2>/dev/null; then
  pass 'a reused pane id never serves the previous session record'
else
  fail "reused pane was shown [$(cat "$got" 2>/dev/null)]"
fi

# Without a session id there is no other identity to key on, so the pane's
# newest record is still the best available answer.
out=$(STUB_TRANSCRIPT_READER="$reader" run_shim nosession \
  HERDR_PANE_ID=w7:p7 AI_AGENT=claude STUB_CAPTURE=/nonexistent)
if grep -q 'DEAD session' "$(field "$out" CLOSEOUT)" 2>/dev/null; then
  pass "a pane with no session id falls back to that pane's newest record"
else
  fail "no-session fallback found nothing: [$(field "$out" CLOSEOUT)]"
fi

# With no recorded closeout the transcript is still preferred over scraping,
# and must work with no session id: ctrl+g lands in panes that never inherited
# the agent's environment, which is precisely where scraping already fails.
transcript_log=$tmpdir/transcript.log
out=$(STUB_TRANSCRIPT_READER="$reader" run_shim transcript \
  HERDR_PANE_ID=w9:p9 AI_AGENT=claude STUB_CAPTURE=/nonexistent \
  AGENT_PROMPT_DEBUG="$transcript_log")
if grep -q 'PROJECT transcript' "$(field "$out" CLOSEOUT)" 2>/dev/null && \
    grep -q "using the agent's transcript" "$transcript_log" 2>/dev/null; then
  pass 'a transcript closeout is used when the pane recorded none'
else
  fail "transcript path not taken: $(cat "$transcript_log" 2>/dev/null)"
fi

leaked=$(find "$tmpdir" -maxdepth 1 -name 'agent-prompt-turn-closeout.w9_p9.*' -print)
if [ -z "$leaked" ]; then
  pass 'the transcript is never written into the pane-scoped record'
else
  fail "the transcript was written into the pane-scoped record: $leaked"
fi

# A non-Claude pane has no ~/.claude transcript of its own, so reading one
# would hand it whichever Claude pane last wrote in this directory.
claude_only_log=$tmpdir/claude-only.log
assert_bare 'a non-Claude pane never reads the Claude transcript' \
  "$(STUB_TRANSCRIPT_READER="$reader" run_shim codex \
    HERDR_PANE_ID=w8:p8 CODEX_THREAD_ID=0199abcd STUB_CAPTURE=/nonexistent \
    AGENT_PROMPT_DEBUG="$claude_only_log")"
if grep -q 'transcripts are Claude-only' "$claude_only_log" 2>/dev/null; then
  pass 'the non-Claude pane records why it read no transcript'
else
  fail "no Claude-only note: $(cat "$claude_only_log" 2>/dev/null)"
fi

# A pane whose checkout was swept still has ctrl+g bound. Neovim inheriting the
# deleted directory makes `uv.cwd()` fail, and every path-less `vim.fs.find` or
# `vim.fs.root` then throws on each autocmd -- InsertEnter included.
swept=$tmpdir/swept
swept_log=$tmpdir/swept.log
mkdir -p "$swept"
out=$(cd "$swept" && rm -rf "$swept" && run_shim swept \
  HERDR_PANE_ID=w6:p6 AI_AGENT=claude STUB_CAPTURE="$fixture" \
  AGENT_PROMPT_DEBUG="$swept_log")
if [ "$(field "$out" PWD)" = "$(CDPATH= cd -- "$HOME" && pwd -P)" ]; then
  pass 'a deleted working directory is replaced before Neovim starts'
else
  fail "Neovim inherited a dead cwd: [$(field "$out" PWD)]"
fi

# The swept pane still gets its closeout: the cwd fix must not cost the feature.
if [ -s "$(field "$out" CLOSEOUT)" ]; then
  pass 'a swept pane still gets its closeout'
else
  fail "swept pane lost its closeout: $(cat "$swept_log" 2>/dev/null)"
fi

printf '1..%d\n' "$((passed + failed))"
if [ "$failed" -ne 0 ]; then
  printf '%d test(s) failed\n' "$failed" >&2
  exit 1
fi
printf 'Agent prompt editor shim test passed.\n'
