#!/usr/bin/env bash
# package.sh — build the organon-v<version>.plugin archive at the repo root.
#
# The .plugin archive is a zip of the plugin tree minus build/eval/git noise.
# Distribution is via GitHub Release asset (the .plugin is gitignored).
#
# Usage:
#   bash skills/plugin-release/scripts/package.sh        # build at repo root
#   bash skills/plugin-release/scripts/package.sh --dry  # list contents only
#
# Reads version from .claude-plugin/plugin.json. Output: organon-v<version>.plugin

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
MANIFEST="${REPO_ROOT}/.claude-plugin/plugin.json"

DRY=0
for arg in "$@"; do
    case "$arg" in
        --dry) DRY=1 ;;
        -h|--help)
            sed -n '2,11p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "error: unknown flag: $arg" >&2
            exit 2
            ;;
    esac
done

require_tool() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "error: required tool not on PATH: $1" >&2
        exit 2
    }
}
require_tool jq
require_tool zip

[[ -f "$MANIFEST" ]] || { echo "error: $MANIFEST not found" >&2; exit 2; }

VERSION="$(jq -r '.version' "$MANIFEST")"
[[ -n "$VERSION" && "$VERSION" != "null" ]] || {
    echo "error: .version missing from $MANIFEST" >&2; exit 2
}

ARCHIVE="${REPO_ROOT}/organon-v${VERSION}.plugin"

cd "$REPO_ROOT"

# Excluded from the archive — keep in sync with .gitignore intent.
EXCLUDES=(
    '.git/*'
    '.git/**/*'
    'eval-workspace/*'
    'eval-workspace/**/*'
    'eval-workspace-*/*'
    'eval-workspace-*/**/*'
    'evals/iteration-*/*'
    'evals/iteration-*/**/*'
    '*.plugin'
    '*.skill'
    '__pycache__/*'
    '**/__pycache__/*'
    '*.pyc'
    '.DS_Store'
    '**/.DS_Store'
    'snippets/*'
    'snippets/**/*'
    '*.bak'
    'zibn6G7I'
)

ZIP_EXCLUDE_ARGS=()
for pattern in "${EXCLUDES[@]}"; do
    ZIP_EXCLUDE_ARGS+=( -x "$pattern" )
done

if [[ "$DRY" -eq 1 ]]; then
    echo "would build: $ARCHIVE"
    echo "from:        $REPO_ROOT"
    echo "contents:"
    zip -r -q -X /tmp/organon-pkg-dry.zip . "${ZIP_EXCLUDE_ARGS[@]}" -x '.claude/*' -x '.claude/**/*'
    zip -r -q -X /tmp/organon-pkg-dry.zip .claude/agents/ "${ZIP_EXCLUDE_ARGS[@]}"
    unzip -l /tmp/organon-pkg-dry.zip
    rm -f /tmp/organon-pkg-dry.zip
    exit 0
fi

[[ -f "$ARCHIVE" ]] && rm -f "$ARCHIVE"

zip -r -q -X "$ARCHIVE" . "${ZIP_EXCLUDE_ARGS[@]}" -x '.claude/*' -x '.claude/**/*'
zip -r -q -X "$ARCHIVE" .claude/agents/ "${ZIP_EXCLUDE_ARGS[@]}"

echo "built:  $ARCHIVE"
echo "size:   $(du -h "$ARCHIVE" | awk '{print $1}')"
echo "files:  $(unzip -l "$ARCHIVE" | tail -1 | awk '{print $2}')"
echo
echo "verify (must be empty):"
unzip -l "$ARCHIVE" | grep -E '(eval-workspace|__pycache__|\.DS_Store|\.git/)' || echo "  (clean)"
