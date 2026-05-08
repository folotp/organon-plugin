#!/usr/bin/env bash
# validate-sync-json.sh — PostToolUse hook for Edit|Write|MultiEdit on kepano-sync.json.
#
# After any edit to kepano-sync.json, validate JSON shape + run
# scripts/sync-kepano.sh --no-fetch --json to confirm the file still parses
# and the script can read it. A malformed entry (wrong body_sha256 length,
# missing target_file, etc.) breaks drift detection silently otherwise.
#
# Reads the hook event JSON from stdin. Exit 2 = surface error to model.

set -euo pipefail

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
SYNC_JSON="${REPO_ROOT}/kepano-sync.json"
SYNC_SCRIPT="${REPO_ROOT}/scripts/sync-kepano.sh"

input="$(cat)"
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null || true)"
[[ -n "$file_path" ]] || exit 0

rel_path="${file_path#${REPO_ROOT}/}"
[[ "$rel_path" == "kepano-sync.json" ]] || exit 0

# 1. JSON shape check.
if ! jq empty "$SYNC_JSON" 2>/dev/null; then
    echo "kepano-sync.json: invalid JSON — fix before proceeding." >&2
    exit 2
fi

# 2. Required schema fields per section.
if ! jq -e '
    .sections | type == "array" and (length > 0) and (
        all(
            has("kepano_skill") and
            has("kepano_section_path") and
            has("kepano_section_heading") and
            has("synced_at_sha") and
            has("body_sha256") and
            has("target_file") and
            (.body_sha256 | test("^[0-9a-f]{64}$"))
        )
    )
' "$SYNC_JSON" >/dev/null 2>&1; then
    echo "kepano-sync.json: schema violation — every section must have" >&2
    echo "  kepano_skill, kepano_section_path, kepano_section_heading," >&2
    echo "  synced_at_sha, body_sha256 (64-hex), target_file." >&2
    exit 2
fi

# 3. Drift detector parses cleanly (no fetch — operates on cached upstream).
if [[ -x "$SYNC_SCRIPT" ]]; then
    if ! "$SYNC_SCRIPT" --no-fetch --json >/dev/null 2>&1; then
        # Exit 1 from the script means drift detected — that is INFORMATIONAL,
        # not a validation failure. Any other non-zero is a real error.
        rc=$?
        if [[ "$rc" -ne 1 ]]; then
            echo "scripts/sync-kepano.sh failed with code $rc after the edit — kepano-sync.json may be malformed." >&2
            exit 2
        fi
    fi
fi

exit 0
