#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
data=$(NVIM_APPNAME=nvim nvim --headless -u NONE \
  '+lua io.write(vim.fn.stdpath("data"))' +qa)
server="$data/site/pack/core/opt/copilot.lua/copilot/js/language-server.js"
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/copilot-lifecycle.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

copilot_orphan_pids() {
  ps -axo pid=,ppid=,command= | awk -v server="$server" '
    $2 == 1 && index($0, server) && $0 ~ /--stdio$/ { print $1 }
  ' | sort -n
}

cleanup_leaks() {
  leaked_file=$1
  while IFS= read -r pid; do
    process=$(ps -p "$pid" -o ppid=,command= 2>/dev/null || true)
    if printf '%s\n' "$process" | awk -v server="$server" '
      $1 == 1 && index($0, server) && $0 ~ /--stdio$/ { found = 1 }
      END { exit !found }
    '; then
      kill -TERM "$pid" 2>/dev/null || true
    fi
  done <"$leaked_file"
}

run_case() {
  mode=$1
  case_dir="$tmpdir/$mode"
  mkdir "$case_dir"
  copilot_orphan_pids >"$case_dir/before"

  if ! NVIM_COPILOT_LIFECYCLE_MODE="$mode" NVIM_APPNAME=nvim \
    nvim --headless \
    '+packadd plenary.nvim' \
    "+PlenaryBustedFile $repo/tests/copilot_lifecycle_spec.lua" \
    >"$case_dir/nvim.log" 2>&1; then
    cat "$case_dir/nvim.log"
    return 1
  fi

  attempt=0
  while [ "$attempt" -lt 15 ]; do
    copilot_orphan_pids >"$case_dir/after"
    comm -13 "$case_dir/before" "$case_dir/after" >"$case_dir/leaked"
    if [ ! -s "$case_dir/leaked" ]; then
      printf 'Copilot %s lifecycle test passed.\n' "$mode"
      return 0
    fi
    attempt=$((attempt + 1))
    sleep 0.2
  done

  printf 'Copilot %s language-server orphans survived Neovim exit:\n' \
    "$mode" >&2
  cat "$case_dir/leaked" >&2
  cleanup_leaks "$case_dir/leaked"
  return 1
}

run_case rapid
run_case active
