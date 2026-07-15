#!/usr/bin/env python3
from __future__ import annotations

import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


def run(*args: str) -> str:
    return subprocess.run(
        args,
        cwd=ROOT,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
    ).stdout.strip()


print(f"Neovim: {run('nvim', '--version').splitlines()[0]}")
status = run("git", "status", "--short")
print("Worktree:")
print(status or "clean")
print("Next check: tools/verify.sh")
print("Manual QA: docs/MANUAL_QA.md")
