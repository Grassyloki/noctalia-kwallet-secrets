#!/usr/bin/env python3
"""Validate PR-BODY.md with upstream's own enforce-pr-template.py.

The CI check matches checklist lines against the template verbatim (whitespace
collapsed), so a paraphrased line fails even while the pull request is a draft.
Rather than copy those strings here and let them drift, this imports the real
script out of the fork checkout, which publish.sh keeps synced to upstream/main.

Usage: check-pr-body.py [--ready]   # --ready also requires every box checked
"""
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

PUBLISHING = Path(__file__).resolve().parent
PR_BODY = PUBLISHING / "PR-BODY.md"  # the body publish.sh feeds to gh
FORK = Path.home() / "Projects" / "noctalia-community-plugins"  # fork checkout, synced to upstream
ENFORCER = FORK / ".github" / "workflows" / "scripts" / "enforce-pr-template.py"

C, Y, G, R = "\033[0;36m", "\033[0;33m", "\033[0;32m", "\033[0;31m"
N = "\033[0m"


def load_enforcer():
    """Import upstream's enforcement script as a module."""
    spec = importlib.util.spec_from_file_location("enforce_pr_template", ENFORCER)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {ENFORCER}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    ready = "--ready" in sys.argv[1:]
    if not ENFORCER.is_file():
        print(f"{Y}skipped: {ENFORCER} not found -- run git fetch in the fork first{N}")
        return 0

    body = PR_BODY.read_text()
    missing = load_enforcer().missing_requirements(body, require_completed=ready)
    if not missing:
        print(f"{G}PR body matches the template"
              f"{' and every required box is checked' if ready else ' (draft rules)'}{N}")
        return 0

    print(f"{R}PR body would be rejected by enforce-pr-template.py:{N}", file=sys.stderr)
    for item in missing:
        print(f"{R}  - {item}{N}", file=sys.stderr)
    print(f"{C}Copy the wording from {FORK}/.github/PULL_REQUEST_TEMPLATE.md exactly.{N}",
          file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
