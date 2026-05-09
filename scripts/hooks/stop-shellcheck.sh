#!/usr/bin/env bash
# stop-shellcheck.sh — Stop hook. Lints any modified bash script under
# scripts/ at session end and prints findings to stderr (non-blocking).
#
# Why: scripts/ holds 7 bash files (sync-kepano.sh, sync-vault.sh, hooks/*.sh)
# whose correctness underwrites release safety. A quoting or POSIX-portability
# regression here is silent until a release attempt fails. Shellcheck at session
# end catches it before the diff lands in a PR.
#
# Behavior:
#   - exit 0 always — Stop hooks must not block session termination.
#   - silent if shellcheck is not on PATH or no scripts/ shell file changed.
#   - reads no stdin context (Stop event input is not needed for this).
#
# Bash compatibility note: this script must run on macOS default bash 3.2
# (no `mapfile`/`readarray`, fragile under `set -u` with empty arrays).
# Avoid bash 4+ builtins; build the file list with a portable while-read
# loop and don't enable `set -u`.

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Discard the hook event JSON on stdin if any.
[[ -t 0 ]] || cat >/dev/null 2>&1 || true

command -v shellcheck >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

cd "$REPO_ROOT" 2>/dev/null || exit 0

# Collect modified + staged + untracked .sh files under scripts/.
# Portable equivalent of `mapfile -t changed < <(...)` — bash 3.2 doesn't
# have mapfile.
changed=()
while IFS= read -r line; do
    [[ -n "$line" ]] && changed+=("$line")
done < <(
    {
        git diff --name-only HEAD -- 'scripts/*.sh' 'scripts/**/*.sh' 2>/dev/null
        git diff --name-only --cached -- 'scripts/*.sh' 'scripts/**/*.sh' 2>/dev/null
        git ls-files --others --exclude-standard -- 'scripts/*.sh' 'scripts/**/*.sh' 2>/dev/null
    } | awk 'NF' | sort -u
)

# Bash 3.2 errors on `${arr[@]}` when arr is empty, even without `set -u`,
# in some contexts. Use the `${arr[@]+...}` guard to default to nothing.
[[ ${#changed[@]} -gt 0 ]] || exit 0

# Filter out files that may have been deleted in the working tree.
existing=()
for f in "${changed[@]}"; do
    [[ -f "$f" ]] && existing+=("$f")
done
[[ ${#existing[@]} -gt 0 ]] || exit 0

# Run shellcheck. -x follows source statements; --severity=warning skips style
# nags so the report stays signal-heavy.
output="$(shellcheck -x --severity=warning "${existing[@]}" 2>&1)" || true

if [[ -n "$output" ]]; then
    {
        echo
        echo "── shellcheck findings (Stop hook) ──"
        echo "scanned: ${existing[*]}"
        echo
        echo "$output"
        echo "──"
        echo "(non-blocking — fix before committing)"
    } >&2
fi

exit 0
