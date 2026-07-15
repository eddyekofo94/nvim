#!/bin/sh
set -eu

repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo"

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/nvim-verify.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

fail_on_nvim_errors() {
  name=$1
  shift
  output="$tmpdir/$name.log"

  if ! NVIM_APPNAME=nvim nvim --headless "$@" >"$output" 2>&1; then
    cat "$output"
    return 1
  fi

  if rg -n "Invalid 'event'|module .* not found|attempt to call|(^|:)Error( |$)|E[0-9]{3,}" "$output"; then
    cat "$output"
    return 1
  fi
}

head -n 3 nvim-version.txt >"$tmpdir/expected-version"
nvim --version | head -n 3 >"$tmpdir/actual-version"
diff -u "$tmpdir/expected-version" "$tmpdir/actual-version"

NVIM_APPNAME=nvim nvim --headless -u NONE \
  '+lua for _, f in ipairs(vim.fn.glob("**/*.lua", false, true)) do local chunk, err = loadfile(f); if not chunk then error(f .. ": " .. err) end end' \
  +qa

luacheck -q \
  lua/core/options.lua \
  lua/core/pack.lua \
  lua/pack/specs/opt/blink-cmp.lua \
  lua/pack/specs/start/dropbar.nvim.lua \
  lua/utils/load.lua \
  lua/utils/pack.lua

fail_on_nvim_errors empty +qa
fail_on_nvim_errors lua lua/utils/pack.lua '+doautocmd InsertEnter' '+sleep 1' +qa
fail_on_nvim_errors markdown README.md '+sleep 1' +qa
fail_on_nvim_errors dropbar lua/utils/pack.lua '+doautocmd FileType lua' +qa

fail_on_nvim_errors integrations lua/utils/pack.lua \
  '+doautocmd InsertEnter' \
  '+lua assert(require("blink.cmp").library_available(), "blink native library unavailable")' \
  '+lua assert(#require("blink.cmp.completion.trigger").show_emitter.listeners > 0, "blink completion trigger is not initialized")' \
  '+lua assert(#require("blink.cmp.sources.lib").completions_emitter.listeners > 0, "blink completion sources are not initialized")' \
  '+lua assert(vim.fn.executable(vim.g.python3_host_prog) == 1, "python provider unavailable")' \
  '+PackInstallAll' \
  +qa

fail_on_nvim_errors lazy_compat README.md \
  '+lua local load=require("utils.load"); load.on_cmds("CodexExact", "__verify_exact_cmd", function() vim.api.nvim_create_user_command("CodexExact", function() vim.g.codex_exact=true end, {}); vim.api.nvim_create_user_command("CodexExactSuffix", function() end, {}) end); vim.cmd.CodexExact(); assert(vim.g.codex_exact == true, "lazy command replay failed")' \
  '+lua local fzf=require("fzf-lua"); fzf.files=function(opts) assert(opts.multiprocess == false, "smart files must avoid multiprocess shell nesting"); local result=vim.system({"sh", "-c", opts.raw_cmd}, {cwd=opts.cwd, text=true}):wait(); assert(result.code == 0, result.stderr); assert(result.stdout:find("README.md", 1, true), "smart files produced no repository files") end; fzf.smart_files()' \
  +qa

# Neovim can be launched by a shell with custom XDG variables or directly by a
# GUI app with the default data path. Both contexts must resolve to the same
# plugin store or one can silently retain stale plugins and native parsers.
nvim_bin=$(command -v nvim)
inherited_data=$(NVIM_APPNAME=nvim "$nvim_bin" --headless -u NONE \
  '+lua io.write(vim.fn.stdpath("data"))' +qa)
default_data=$(env -i HOME="$HOME" PATH="/usr/bin:/bin" NVIM_APPNAME=nvim \
  TERM=xterm-256color "$nvim_bin" --headless -u NONE \
  '+lua io.write(vim.fn.stdpath("data"))' +qa)

if [ "$(realpath "$inherited_data")" != "$(realpath "$default_data")" ]; then
  printf 'Neovim data roots diverge:\n  inherited: %s\n  default: %s\n' \
    "$inherited_data" "$default_data" >&2
  exit 1
fi

clean_output="$tmpdir/clean-environment.log"
if ! env -i HOME="$HOME" PATH="/usr/bin:/bin" NVIM_APPNAME=nvim \
  TERM=xterm-256color "$nvim_bin" --headless README.md \
  '+lua vim.cmd.packadd("dropbar.nvim"); require("dropbar").setup()' \
  '+sleep 1' +qa >"$clean_output" 2>&1; then
  cat "$clean_output"
  exit 1
fi
if rg -n "Invalid 'event'|incompatible architecture|Error in (FileType|LspAttach|BufReadPost)|E[0-9]{3,}" "$clean_output"; then
  cat "$clean_output"
  exit 1
fi

plugin_root=$(NVIM_APPNAME=nvim nvim --headless -u NONE \
  '+lua io.write(vim.fs.joinpath(vim.fn.stdpath("data"), "site/pack/core/opt"))' \
  +qa)

for plugin in "$plugin_root"/*; do
  [ -d "$plugin/.git" ] || continue
  git -C "$plugin" rev-parse --verify HEAD >/dev/null
  changes=$(git -C "$plugin" status --porcelain=v1 | rg -v '^\?\? doc/tags$' || true)
  if [ -n "$changes" ]; then
    printf 'Dirty plugin checkout: %s\n%s\n' "$plugin" "$changes" >&2
    exit 1
  fi
done

printf 'Neovim verification passed.\n'
