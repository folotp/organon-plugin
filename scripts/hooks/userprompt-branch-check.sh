#!/usr/bin/env bash
# userprompt-branch-check.sh — UserPromptSubmit hook.
#
# Surfaces the repo's branch policy at the moment it matters — when the user
# submits a prompt while still on `main`. Per CLAUDE.md:
#
#   "Never commit directly to main. Required pattern: feature/release branch
#    → PR → merge-commit."
#
# The pre-commit hook ultimately enforces this, but a pre-commit refusal
# arrives late (after the model has already drafted a commit message and
# staged files). This hook surfaces the rule earlier — at prompt time —
# so the model switches to a branch BEFORE doing implementation work.
#
# Behavior:
#   - on main      → emits a one-line context-injection notice on stdout
#                    (UserPromptSubmit stdout is added to the model's context
#                    when exit=0).
#   - off main     → silent, exit 0.
#   - detached HEAD → silent (rare; usually intentional for inspection).
#   - not a repo   → silent.
#
# Always exit 0. This hook is informational — it never blocks prompt submission.

set -u

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Discard the prompt-event JSON on stdin (we don't need it).
[[ -t 0 ]] || cat >/dev/null 2>&1 || true

command -v git >/dev/null 2>&1 || exit 0

# `git symbolic-ref --short HEAD` returns the branch name on a normal
# checkout; errors (rc != 0) on detached HEAD or outside a repo.
branch="$(git -C "$REPO_ROOT" symbolic-ref --short HEAD 2>/dev/null)" || exit 0

[[ "$branch" = "main" ]] || exit 0

# Stdout becomes context injected into the model's next turn. Keep it terse —
# one line, no decoration, so it reads as a system reminder rather than chat.
echo "Branch reminder: currently on main. Per CLAUDE.md, this repo requires a feat/ fix/ chore/ perf/ docs/ prefixed branch before any commit. Run \`git checkout -b <prefix>/<short-description>\` before staging changes."
exit 0
