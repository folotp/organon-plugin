#!/usr/bin/env bash
# block-absorbed-edits.sh — PreToolUse hook for Edit|Write|MultiEdit.
#
# Blocks direct edits to files registered in kepano-sync.json as `target_file`
# entries (the absorbed-from-kepano refs). Direct edits silently invalidate
# the body_sha256 fingerprint and produce false drift on the next
# scripts/sync-kepano.sh run.
#
# To resolve drift legitimately, route through the kepano-resync skill or
# the kepano-drift-resolver subagent.
#
# Reads the hook event JSON from stdin. Exit 2 = block (stderr shown to model).

set -euo pipefail

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
SYNC_JSON="${REPO_ROOT}/kepano-sync.json"

[[ -f "$SYNC_JSON" ]] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"
[[ -n "$file_path" ]] || exit 0

# Normalize: strip the repo root prefix if present, so we compare in the same
# space as kepano-sync.json's relative `target_file` paths.
rel_path="${file_path#${REPO_ROOT}/}"

# Match if rel_path equals any target_file in kepano-sync.json.
if jq -e --arg p "$rel_path" '.sections[] | select(.target_file == $p)' \
        "$SYNC_JSON" >/dev/null 2>&1; then
    cat >&2 <<EOF
Blocked: $rel_path is an absorbed-kepano file tracked in kepano-sync.json.

Direct edits invalidate the body_sha256 fingerprint and produce false drift
on the next scripts/sync-kepano.sh run.

To update absorbed content correctly, route through:
  - the kepano-resync skill (user-invokable: /kepano-resync), OR
  - the kepano-drift-resolver subagent for fan-out across multiple sections.

If you intend to remove the file from kepano absorption (intentional
de-absorption), delete the kepano-sync.json entry first, then edit the
file as Organon-owned content.
EOF
    exit 2
fi

exit 0
