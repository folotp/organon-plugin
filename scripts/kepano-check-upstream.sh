#!/usr/bin/env bash
# kepano-check-upstream.sh — compare pinned kepano sha vs upstream HEAD.
#
# Replaces sync-kepano.sh (317 LoC, bidirectional body-hash compare).
# The v1.0.0 contract is sha-pin only: we trust that the absorbed bytes
# match upstream at the pinned sha, and flag drift when upstream advances.
# Refresh runbook: docs/refreshing-kepano.md.
#
# Exit codes:
#   0  in-sync (upstream HEAD == pinned sha)
#   1  drift (upstream advanced)
#   2  gate-unavailable (git missing, network unreachable, version file malformed)

set -u

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
VERSION_FILE="${REPO_ROOT}/kepano-version.txt"
UPSTREAM_URL="https://github.com/kepano/obsidian-skills.git"

QUIET=0
NO_FETCH=0
for arg in "$@"; do
    case "$arg" in
        --quiet | -q) QUIET=1 ;;
        --no-fetch) NO_FETCH=1 ;;
        -h | --help)
            sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "error: unknown flag: $arg" >&2
            exit 2
            ;;
    esac
done

command -v git >/dev/null 2>&1 || {
    [[ "$QUIET" -eq 1 ]] || echo "kepano: ⚠ git not available" >&2
    exit 2
}

[[ -f "$VERSION_FILE" ]] || {
    [[ "$QUIET" -eq 1 ]] || echo "kepano: ⚠ $VERSION_FILE not found" >&2
    exit 2
}

pinned="$(awk -F'@' 'NR==1 {print $2}' "$VERSION_FILE" | tr -d '[:space:]')"
[[ -n "$pinned" ]] || {
    [[ "$QUIET" -eq 1 ]] || echo "kepano: ⚠ pinned sha missing from $VERSION_FILE (expected kepano/obsidian-skills@<sha>)" >&2
    exit 2
}

if [[ "$NO_FETCH" -eq 1 ]]; then
    [[ "$QUIET" -eq 1 ]] || echo "kepano: ✓ pinned at $pinned (no-fetch — upstream HEAD not checked)"
    exit 0
fi

upstream="$(git ls-remote "$UPSTREAM_URL" HEAD 2>/dev/null | awk '{print $1}')"
[[ -n "$upstream" ]] || {
    [[ "$QUIET" -eq 1 ]] || echo "kepano: ⚠ could not fetch upstream HEAD from $UPSTREAM_URL" >&2
    exit 2
}

if [[ "$pinned" == "$upstream" ]]; then
    [[ "$QUIET" -eq 1 ]] || echo "kepano: ✓ in-sync at $pinned"
    exit 0
fi

[[ "$QUIET" -eq 1 ]] || cat <<EOF
kepano: ⚠ upstream advanced
  pinned:   $pinned
  upstream: $upstream

Refresh runbook: docs/refreshing-kepano.md
EOF
exit 1
