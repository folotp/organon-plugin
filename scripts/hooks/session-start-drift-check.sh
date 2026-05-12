#!/usr/bin/env bash
# session-start-drift-check.sh — SessionStart hook for the organon-plugin repo.
#
# Runs the kepano drift detector at session open as a passive integrity check.
# Uses --no-fetch (cached upstream) for ~150 ms cost.
#
# Outcomes:
#   - clean (exit 0)            → "✓ in-sync"
#   - drift (exit 1)            → "⚠ drift detected — run /kepano-resync"
#   - gate-unavailable (rc ≥ 2) → "⚠ gate unavailable rc=N"
#
# Read-only; always exits 0 so the session opens normally.

set -u

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
KEPANO_SCRIPT="${REPO_ROOT}/scripts/sync-kepano.sh"

kepano_summary() {
    if [[ ! -x "$KEPANO_SCRIPT" ]]; then
        echo "  kepano: script not found at $KEPANO_SCRIPT"
        return
    fi
    local out rc
    out="$("$KEPANO_SCRIPT" --no-fetch 2>&1)"
    rc=$?
    case "$rc" in
        0) echo "  kepano: ✓ all sections in-sync (cached upstream)" ;;
        1)
            local drifted
            drifted="$(printf '%s\n' "$out" | awk '/[a-z-]+ +[a-z-]+ +.* +[a-f0-9]{7,} +(upstream-changed|heading-removed|heading-renamed|upstream-file-missing|target-corrupt|target-marker-missing|target-file-missing)/ {print $1"/"$2}' | head -3 | tr '\n' ' ')"
            echo "  kepano: ⚠ drift detected — run /kepano-resync (${drifted:-see ./scripts/sync-kepano.sh})"
            ;;
        *)
            echo "  kepano: ⚠ gate unavailable rc=$rc (network/config — defer to /plugin-release pre-flight)"
            ;;
    esac
}

echo "organon-plugin drift integrity check:"
kepano_summary

exit 0
