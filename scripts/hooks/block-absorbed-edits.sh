#!/usr/bin/env bash
# block-absorbed-edits.sh — PreToolUse hook for Edit|Write|MultiEdit.
#
# Blocks direct edits to files registered as `target_file` entries in EITHER:
#   - kepano-sync.json (.sections[].target_file) — content absorbed from
#     upstream kepano/obsidian-skills.
#   - vault-sync.json (.entries[].target_file) — content absorbed from the
#     local Organon vault registres + vocabulaires.
#
# Direct edits silently invalidate the body_sha256 fingerprint and produce
# false drift on the next scripts/sync-*.sh run (or, worse for vault-sync,
# go undetected because sync-vault.sh hashes only the live vault file, not
# the plugin target).
#
# To resolve drift legitimately, route through the appropriate workflow:
#   - kepano: kepano-resync skill or kepano-drift-resolver subagent.
#   - vault:  manual re-sync per docs/syncing-vault.md (no skill yet).
#
# Reads the hook event JSON from stdin. Exit 2 = block (stderr shown to model).

set -euo pipefail

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
KEPANO_JSON="${REPO_ROOT}/kepano-sync.json"
VAULT_JSON="${REPO_ROOT}/vault-sync.json"
TOKEN_FILE="${REPO_ROOT}/.organon-resync-token"

command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"
[[ -n "$file_path" ]] || exit 0

# Normalize: strip the repo root prefix if present, then strip a leading ./
# so we compare in the same space as the relative `target_file` paths in
# the sync JSONs (which never carry a ./ prefix). Both kepano and vault
# matching depend on this canonical form.
rel_path="${file_path#"${REPO_ROOT}"/}"
rel_path="${rel_path#./}"

# Scoped-token bypass for legitimate re-sync flows.
#
# The kepano-resync and vault-resync skills (and the kepano-drift-resolver
# subagent) need to write inside <!-- KEPANO/VAULT-* --> markers on absorbed
# target files. The legitimate flow drops a .organon-resync-token file at
# repo root listing the rel_paths it intends to edit — one per line; blank
# lines and # comments tolerated. If the requested rel_path appears, the
# hook allows the edit and emits an audit line to stderr.
#
# The pre-commit hook refuses to commit while the token exists, so a leaked
# token can't slip into history. The token is .gitignored.
#
# This bypass is scoped (specific paths only), auditable (stderr per call),
# and short-lived (skill removes it after the edit batch). It does NOT
# disable the hook globally — direct edits to absorbed paths NOT listed in
# the token are still blocked.
if [[ -f "$TOKEN_FILE" ]]; then
    if grep -v '^[[:space:]]*\(#\|$\)' "$TOKEN_FILE" 2>/dev/null \
         | grep -Fxq "$rel_path"; then
        echo "block-absorbed-edits.sh: edit allowed by .organon-resync-token for: $rel_path" >&2
        exit 0
    fi
fi

# Match against kepano-sync.json (.sections[].target_file).
if [[ -f "$KEPANO_JSON" ]] && \
   jq -e --arg p "$rel_path" '.sections[] | select(.target_file == $p)' \
        "$KEPANO_JSON" >/dev/null 2>&1; then
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

For a legitimate re-sync via the kepano-resync skill, drop a one-line
.organon-resync-token at repo root scoping this path before editing.
The skill body documents the lifecycle.
EOF
    exit 2
fi

# Match against vault-sync.json (.entries[].target_file).
# Note: sync-vault.sh hashes only the live vault file, not the plugin target,
# so a direct edit here is silently invisible to the drift detector — making
# the hook the *primary* protection for these files.
if [[ -f "$VAULT_JSON" ]] && \
   jq -e --arg p "$rel_path" '.entries[] | select(.target_file == $p)' \
        "$VAULT_JSON" >/dev/null 2>&1; then
    cat >&2 <<EOF
Blocked: $rel_path is an absorbed-vault file tracked in vault-sync.json.

Direct edits invalidate the body_sha256 fingerprint AND go undetected by
scripts/sync-vault.sh (which hashes the live vault file only, not the
plugin target). Silent divergence from both vault and stored fingerprint.

To update absorbed content correctly, route through the manual re-sync
workflow:
  - docs/syncing-vault.md — step-by-step procedure
  - re-extract from the vault source listed in the entry's vault_path
  - update body_sha256 and synced_at_date in vault-sync.json
  - re-run scripts/sync-vault.sh — must report in-sync

If you intend to remove the file from vault absorption (intentional
de-absorption), delete the vault-sync.json entry first, then edit the
file as Organon-owned content.

For a legitimate re-sync via the vault-resync skill, drop a one-line
.organon-resync-token at repo root scoping this path before editing.
The skill body documents the lifecycle.
EOF
    exit 2
fi

exit 0
