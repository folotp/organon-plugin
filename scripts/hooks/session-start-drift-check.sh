#!/usr/bin/env bash
# session-start-drift-check.sh — SessionStart hook for the organon-plugin repo.
#
# Runs the kepano + vault drift detectors at session open as a passive
# integrity check. Both detectors are local-only (kepano with --no-fetch,
# vault always reads the live filesystem), so the cost is ~200-300 ms total.
#
# Output goes into the session header — concise one-line summaries per
# detector. Drift is informational, not blocking: the hook always exits 0
# so the session opens normally, with the drift status visible at the top.
#
# Distinguishes three outcomes per detector (matching the same contract as
# /organon-memory-audit pole 1):
#   - clean (exit 0)            → "✓ in-sync"
#   - drift (exit 1)            → "⚠ drift detected — run /kepano-resync"
#   - gate-unavailable (rc ≥ 2) → "⚠ gate unavailable rc=N (network/config)"
#
# Read-only: never auto-fixes, never edits files.

set -u

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
KEPANO_SCRIPT="${REPO_ROOT}/scripts/sync-kepano.sh"
VAULT_SCRIPT="${REPO_ROOT}/scripts/sync-vault.sh"

# Run kepano detector (cached upstream, no fetch — keeps session-open cost low).
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

# Run vault detector (live filesystem read).
vault_summary() {
    if [[ ! -x "$VAULT_SCRIPT" ]]; then
        echo "  vault:  script not found at $VAULT_SCRIPT"
        return
    fi
    local out rc
    out="$("$VAULT_SCRIPT" 2>&1)"
    rc=$?
    case "$rc" in
        0) echo "  vault:  ✓ all entries in-sync" ;;
        1) echo "  vault:  ⚠ drift detected — see docs/syncing-vault.md" ;;
        *) echo "  vault:  ⚠ gate unavailable rc=$rc (vault path missing or config error)" ;;
    esac
}

echo "organon-plugin drift integrity check:"
kepano_summary
vault_summary

# Always exit 0 — drift is informational, not session-blocking.
exit 0
