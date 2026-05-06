#!/usr/bin/env bash
# sync-kepano.sh — Detect drift between absorbed kepano content and upstream HEAD.
# Read-only: never auto-commits, never auto-edits files. Produces a report.
#
# Usage:
#   scripts/sync-kepano.sh                  # report-only (default)
#   scripts/sync-kepano.sh --no-fetch       # skip git fetch (use cached repo as-is)
#   scripts/sync-kepano.sh --json           # emit JSON report instead of text
#
# Exit codes:
#   0 — all sections in-sync
#   1 — drift detected (upstream-changed, heading-renamed, or heading-removed)
#   2 — usage / dependency / config error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SYNC_JSON="${REPO_ROOT}/kepano-sync.json"
CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/organon-plugin/kepano-skills"

FETCH=1
EMIT_JSON=0
for arg in "$@"; do
    case "$arg" in
        --no-fetch) FETCH=0 ;;
        --json) EMIT_JSON=1 ;;
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
require_tool git
require_tool jq
require_tool sha256sum || require_tool shasum

sha256_of() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum | awk '{print $1}'
    else
        shasum -a 256 | awk '{print $1}'
    fi
}

[[ -f "$SYNC_JSON" ]] || {
    echo "error: $SYNC_JSON not found" >&2
    exit 2
}

UPSTREAM_URL="$(jq -r '.upstream.url' "$SYNC_JSON")"
UPSTREAM_BRANCH="$(jq -r '.upstream.default_branch' "$SYNC_JSON")"

# --- Cache management -------------------------------------------------------

if [[ ! -d "${CACHE_DIR}/.git" ]]; then
    mkdir -p "$(dirname "$CACHE_DIR")"
    echo ">> cloning $UPSTREAM_URL into $CACHE_DIR"
    git clone --quiet --depth=50 --branch "$UPSTREAM_BRANCH" "$UPSTREAM_URL" "$CACHE_DIR"
elif [[ "$FETCH" -eq 1 ]]; then
    echo ">> fetching origin/$UPSTREAM_BRANCH in $CACHE_DIR"
    git -C "$CACHE_DIR" fetch --quiet --depth=50 origin "$UPSTREAM_BRANCH"
    git -C "$CACHE_DIR" checkout --quiet "origin/$UPSTREAM_BRANCH"
fi

UPSTREAM_HEAD="$(git -C "$CACHE_DIR" rev-parse "origin/$UPSTREAM_BRANCH" 2>/dev/null || git -C "$CACHE_DIR" rev-parse HEAD)"
UPSTREAM_HEAD_SHORT="${UPSTREAM_HEAD:0:7}"

# --- Body / section extraction ---------------------------------------------

# SKILL.md body: everything after the second `---` line, byte-for-byte.
extract_skill_body() {
    awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$1"
}

# Extract a heading-scoped section: from `## <heading>` (or any depth) to the
# next heading at equal-or-shallower depth, or EOF.
extract_section() {
    local file="$1"
    local heading="$2"
    awk -v target="$heading" '
        function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
        BEGIN { in_section = 0; depth = 0 }
        /^#+[[:space:]]/ {
            match($0, /^#+/)
            cur_depth = RLENGTH
            cur_text = trim(substr($0, RLENGTH + 1))
            if (in_section && cur_depth <= depth) {
                in_section = 0
            }
            if (!in_section && cur_text == target) {
                in_section = 1
                depth = cur_depth
                print
                next
            }
        }
        in_section { print }
    ' "$file"
}

# --- Per-section drift check ------------------------------------------------

REPORT_ROWS=()    # human-readable report rows
JSON_ROWS=()      # JSON report rows
EXIT_DRIFT=0

n_sections="$(jq '.sections | length' "$SYNC_JSON")"
for i in $(seq 0 $((n_sections - 1))); do
    kepano_skill="$(jq -r ".sections[$i].kepano_skill" "$SYNC_JSON")"
    section_path="$(jq -r ".sections[$i].kepano_section_path" "$SYNC_JSON")"
    section_heading="$(jq -r ".sections[$i].kepano_section_heading" "$SYNC_JSON")"
    synced_at_sha="$(jq -r ".sections[$i].synced_at_sha" "$SYNC_JSON")"
    synced_at_date="$(jq -r ".sections[$i].synced_at_date" "$SYNC_JSON")"
    stored_sha256="$(jq -r ".sections[$i].body_sha256" "$SYNC_JSON")"
    target_file="$(jq -r ".sections[$i].target_file" "$SYNC_JSON")"
    stored_status="$(jq -r ".sections[$i].drift_status" "$SYNC_JSON")"

    src_file="${CACHE_DIR}/${section_path}"
    detected_status="unknown"
    detected_sha256=""

    if [[ ! -f "$src_file" ]]; then
        detected_status="upstream-file-missing"
    else
        # Capture body in a temp file (preserves trailing newlines exactly,
        # which bash $() command substitution would strip).
        body_file="$(mktemp)"
        case "$section_heading" in
            "(full body)")
                extract_skill_body "$src_file" > "$body_file"
                ;;
            "(full file)")
                cat "$src_file" > "$body_file"
                ;;
            *)
                extract_section "$src_file" "$section_heading" > "$body_file"
                ;;
        esac

        if [[ ! -s "$body_file" ]]; then
            detected_status="heading-removed"
        else
            detected_sha256="$(sha256_of < "$body_file")"
            if [[ "$detected_sha256" == "$stored_sha256" ]]; then
                detected_status="in-sync"
            else
                detected_status="upstream-changed"
            fi
        fi
        rm -f "$body_file"
    fi

    if [[ "$detected_status" != "in-sync" ]]; then
        EXIT_DRIFT=1
    fi

    REPORT_ROWS+=("$(printf '%s|%s|%s|%s|%s|%s|%s' \
        "$kepano_skill" "$section_path" "$section_heading" \
        "$synced_at_sha" "$synced_at_date" \
        "$detected_status" "$target_file")")
    JSON_ROWS+=("$(jq -n \
        --arg ks "$kepano_skill" \
        --arg sp "$section_path" \
        --arg sh "$section_heading" \
        --arg sa "$synced_at_sha" \
        --arg sd "$synced_at_date" \
        --arg ss "$stored_sha256" \
        --arg ds "$detected_sha256" \
        --arg st "$detected_status" \
        --arg tf "$target_file" \
        '{kepano_skill:$ks,kepano_section_path:$sp,kepano_section_heading:$sh,synced_at_sha:$sa,synced_at_date:$sd,stored_sha256:$ss,detected_sha256:$ds,detected_status:$st,target_file:$tf}')")
done

# --- Emit report ------------------------------------------------------------

if [[ "$EMIT_JSON" -eq 1 ]]; then
    jq -n \
        --arg url "$UPSTREAM_URL" \
        --arg branch "$UPSTREAM_BRANCH" \
        --arg head "$UPSTREAM_HEAD" \
        --argjson sections "$(printf '%s\n' "${JSON_ROWS[@]}" | jq -s '.')" \
        '{upstream:{url:$url,default_branch:$branch,head:$head},sections:$sections}'
else
    echo
    echo "kepano upstream: $UPSTREAM_URL @ $UPSTREAM_BRANCH"
    echo "upstream HEAD:   $UPSTREAM_HEAD_SHORT ($UPSTREAM_HEAD)"
    echo "config:          $SYNC_JSON"
    echo "cache:           $CACHE_DIR"
    echo
    printf '  %-20s %-50s %-25s %-9s %-19s\n' "skill" "section_path" "heading" "synced" "status"
    printf '  %-20s %-50s %-25s %-9s %-19s\n' "-----" "------------" "-------" "------" "------"
    for row in "${REPORT_ROWS[@]}"; do
        IFS='|' read -r ks sp sh sa sd st tf <<< "$row"
        printf '  %-20s %-50s %-25s %-9s %-19s\n' \
            "$ks" "$sp" "$sh" "${sa:0:7}" "$st"
    done
    echo
    if [[ "$EXIT_DRIFT" -eq 0 ]]; then
        echo "✓ all sections in-sync"
    else
        echo "drift detected — review and update absorbed content + body_sha256 + synced_at_sha"
        echo "  workflow: see docs/syncing-kepano.md"
    fi
fi

exit $EXIT_DRIFT
