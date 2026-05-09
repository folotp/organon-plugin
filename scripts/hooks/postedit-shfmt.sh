#!/usr/bin/env bash
# postedit-shfmt.sh — PostToolUse hook for Edit|Write|MultiEdit.
#
# Detects formatting drift in shell scripts (*.sh) after the model edits them.
# Matches the repo's prevailing style (4-space indent, switch-case indent).
# Companion to stop-shellcheck.sh: shellcheck catches correctness issues at
# session end, shfmt-detect surfaces formatting drift at edit time so style
# regressions don't accumulate between PRs.
#
# Mode: DETECT-ONLY (shfmt -d). The hook prints the diff to stderr if the
# file would be reformatted, but never modifies the file. Rationale:
#   - never invalidates the model's view of the file mid-session,
#   - matches the existing detect-not-fix philosophy (stop-shellcheck.sh,
#     the drift detectors, the absorbed-edits blocker),
#   - the model can apply `shfmt -i 4 -ci -w <file>` explicitly when ready.
#
# Behavior:
#   - silent and non-blocking if shfmt is not on PATH (matches stop-shellcheck
#     pattern — installing the tool is opt-in via `brew install shfmt`).
#   - silent and non-blocking if the edited file is not a *.sh file or lives
#     outside the repo root.
#   - exit 0 always — detection is best-effort, must never break the edit.
#   - on detected drift: prints a one-line summary plus the diff to stderr.
#
# Reads the hook event JSON from stdin and extracts .tool_input.file_path.
#
# Bash 3.2 compatible (macOS default) — no mapfile, no [[:print:]] tricks.

set -u

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

command -v shfmt >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"
[[ -n "$file_path" ]] || exit 0

# Only handle *.sh inside the repo. Absolute paths from the model are
# normalised against REPO_ROOT first.
case "$file_path" in
    *.sh) ;;
    *) exit 0 ;;
esac

rel_path="${file_path#"${REPO_ROOT}"/}"
rel_path="${rel_path#./}"

# Reject paths that escape the repo (e.g., /etc/foo.sh that the model may have
# been given access to). shfmt'ing arbitrary system files is out of scope.
case "$rel_path" in
    /*) exit 0 ;;
esac

abs_path="${REPO_ROOT}/${rel_path}"
[[ -f "$abs_path" ]] || exit 0

# Style flags match the existing scripts/ corpus:
#   -i 4   → 4-space indentation (block-absorbed-edits.sh, sync-*.sh)
#   -ci    → indent switch cases
#   -bn    → omitted intentionally; existing scripts put `&& \` at line end,
#            and -bn would break that pattern by moving binops to next line.
#
# -d emits the diff that -w would apply on stdout, and uses rc=1 to signal
# "diff found" (not error). rc≥2 is a real failure (parse error, missing
# file). Use `|| true` to keep rc=1 from short-circuiting the script; if
# shfmt errored hard, stderr is suppressed and stdout will be empty, which
# the next check catches.
diff_out="$(shfmt -i 4 -ci -d "$abs_path" 2>/dev/null || true)"
[[ -n "$diff_out" ]] || exit 0

{
    echo "postedit-shfmt: format drift in $rel_path"
    echo "  apply with: shfmt -i 4 -ci -w $rel_path"
    echo
    echo "$diff_out"
} >&2
exit 0
