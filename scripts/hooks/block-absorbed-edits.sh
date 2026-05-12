#!/usr/bin/env bash
# block-absorbed-edits.sh — PreToolUse hook for Edit|Write|MultiEdit.
#
# Blocks direct edits to the 9 kepano-absorbed references. The plugin pins
# one upstream sha for kepano/obsidian-skills in kepano-version.txt; the
# refresh path is documented in docs/refreshing-kepano.md and involves
# updating these files alongside a sha bump. Casual edits to them silently
# drift the plugin from its declared upstream pin.
#
# The 9 paths are hardcoded — there is no per-file ledger after v1.0.0.
#
# Reads the hook event JSON from stdin. Exit 2 = block (stderr shown to model).

set -euo pipefail

REPO_ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
TOKEN_FILE="${REPO_ROOT}/.organon-resync-token"

ABSORBED_PATHS=(
    "skills/organon-bases/references/BASES_SYNTAX.md"
    "skills/organon-bases/references/FUNCTIONS_REFERENCE.md"
    "skills/organon-canvas/references/CANVAS_SPEC.md"
    "skills/organon-canvas/references/EXAMPLES.md"
    "skills/organon-diagramming/references/MERMAID_SYNTAX.md"
    "skills/organon-frontmatter/references/PROPERTIES.md"
    "skills/organon-markdown-style/references/CALLOUTS.md"
    "skills/organon-markdown-style/references/EMBEDS.md"
    "skills/organon-markdown-style/references/MARKDOWN_SYNTAX.md"
)

command -v jq >/dev/null 2>&1 || exit 0

input="$(cat)"
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"
[[ -n "$file_path" ]] || exit 0

rel_path="${file_path#"${REPO_ROOT}"/}"
rel_path="${rel_path#./}"

# Scoped-token bypass for kepano refresh flows. Drop a .organon-resync-token
# at repo root listing the rel_paths to edit (one per line). The pre-commit
# hook refuses to commit while the token exists, so leakage is impossible.
if [[ -f "$TOKEN_FILE" ]]; then
    if grep -v '^[[:space:]]*\(#\|$\)' "$TOKEN_FILE" 2>/dev/null |
        grep -Fxq "$rel_path"; then
        echo "block-absorbed-edits.sh: edit allowed by .organon-resync-token for: $rel_path" >&2
        exit 0
    fi
fi

for absorbed in "${ABSORBED_PATHS[@]}"; do
    if [[ "$rel_path" == "$absorbed" ]]; then
        cat >&2 <<EOF
Blocked: $rel_path is a kepano-absorbed reference pinned to
kepano/obsidian-skills@\$(cat kepano-version.txt).

Direct edits drift the file from its declared upstream pin. To refresh
this content correctly, follow docs/refreshing-kepano.md: bump
kepano-version.txt to the new upstream sha and rewrite the affected
references in the same commit.

For a scoped edit under the refresh flow, drop a .organon-resync-token
at repo root listing this path before editing.
EOF
        exit 2
    fi
done

exit 0
