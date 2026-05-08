#!/usr/bin/env bash
# sync-vault.sh — Detect drift between absorbed vault content and the live Organon vault.
# Read-only: never auto-commits, never auto-edits files. Produces a report.
#
# Usage:
#   scripts/sync-vault.sh                  # report-only (default)
#   scripts/sync-vault.sh --json           # emit JSON report instead of text
#
# Exit codes:
#   0 — all entries in-sync
#   1 — drift detected (vault-changed, section-missing, vault-file-missing)
#   2 — usage / dependency / config error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SYNC_JSON="${REPO_ROOT}/vault-sync.json"

EMIT_JSON=0
for arg in "$@"; do
    case "$arg" in
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
require_tool jq
command -v sha256sum >/dev/null 2>&1 || command -v shasum >/dev/null 2>&1 || {
    echo "error: neither sha256sum nor shasum on PATH" >&2
    exit 2
}

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

VAULT_ROOT_RAW="$(jq -r '.vault_root' "$SYNC_JSON")"
# Expand a leading ~ to $HOME (jq returns the literal string).
VAULT_ROOT="${VAULT_ROOT_RAW/#\~/$HOME}"

[[ -d "$VAULT_ROOT" ]] || {
    echo "error: vault_root not a directory: $VAULT_ROOT" >&2
    exit 2
}

# --- Body / section extraction ---------------------------------------------

# Extract everything after the second `---` line (note body, byte-for-byte).
extract_full_body() {
    awk 'BEGIN{n=0} /^---$/{n++; next} n>=2{print}' "$1"
}

# Extract a heading-scoped section's BODY (without the heading line).
# Stops at the next heading at equal-or-shallower depth, or EOF.
extract_section_body() {
    local file="$1"
    local heading="$2"
    awk -v target="$heading" '
        function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
        BEGIN { in_section = 0; depth = 0 }
        /^#+[[:space:]]/ {
            match($0, /^#+/)
            cur_depth = RLENGTH
            cur_text = trim(substr($0, RLENGTH + 1))
            if (in_section && cur_depth <= depth) { in_section = 0 }
            if (!in_section && cur_text == target) {
                in_section = 1
                depth = cur_depth
                next
            }
        }
        in_section { print }
    ' "$file"
}

# --- Per-entry drift check --------------------------------------------------

REPORT_ROWS=()    # human-readable report rows
JSON_ROWS=()      # JSON report rows
EXIT_DRIFT=0

n_entries="$(jq '.entries | length' "$SYNC_JSON")"
for i in $(seq 0 $((n_entries - 1))); do
    vault_path="$(jq -r ".entries[$i].vault_path" "$SYNC_JSON")"
    section_heading="$(jq -r ".entries[$i].section_heading" "$SYNC_JSON")"
    extract_mode="$(jq -r ".entries[$i].extract_mode" "$SYNC_JSON")"
    synced_at_date="$(jq -r ".entries[$i].synced_at_date" "$SYNC_JSON")"
    stored_sha256="$(jq -r ".entries[$i].body_sha256" "$SYNC_JSON")"
    target_file="$(jq -r ".entries[$i].target_file" "$SYNC_JSON")"

    src_file="${VAULT_ROOT}/${vault_path}"
    detected_status="unknown"
    detected_sha256=""

    if [[ ! -f "$src_file" ]]; then
        detected_status="vault-file-missing"
    else
        # Snapshot to mktemp first — vault files can be rewritten mid-script
        # by Obsidian / Linter / iCloud sync. Hashing the snapshot is atomic.
        snapshot="$(mktemp)"
        cp "$src_file" "$snapshot"

        body_file="$(mktemp)"
        case "$extract_mode" in
            "full-body")
                extract_full_body "$snapshot" > "$body_file"
                ;;
            "section-body")
                extract_section_body "$snapshot" "$section_heading" > "$body_file"
                ;;
            *)
                echo "error: unknown extract_mode: $extract_mode (entry $i)" >&2
                rm -f "$snapshot" "$body_file"
                exit 2
                ;;
        esac

        if [[ ! -s "$body_file" ]]; then
            detected_status="section-missing"
        else
            detected_sha256="$(sha256_of < "$body_file")"
            if [[ "$detected_sha256" == "$stored_sha256" ]]; then
                detected_status="in-sync"
            else
                detected_status="vault-changed"
            fi
        fi
        rm -f "$snapshot" "$body_file"
    fi

    if [[ "$detected_status" != "in-sync" ]]; then
        EXIT_DRIFT=1
    fi

    label="${section_heading}"
    [[ "$extract_mode" == "full-body" ]] && label="(full body)"

    REPORT_ROWS+=("$(printf '%s|%s|%s|%s|%s' \
        "$vault_path" "$label" \
        "$synced_at_date" \
        "$detected_status" "$target_file")")
    JSON_ROWS+=("$(jq -n \
        --arg vp "$vault_path" \
        --arg sh "$section_heading" \
        --arg em "$extract_mode" \
        --arg sd "$synced_at_date" \
        --arg ss "$stored_sha256" \
        --arg ds "$detected_sha256" \
        --arg st "$detected_status" \
        --arg tf "$target_file" \
        '{vault_path:$vp,section_heading:$sh,extract_mode:$em,synced_at_date:$sd,stored_sha256:$ss,detected_sha256:$ds,detected_status:$st,target_file:$tf}')")
done

# --- Emit report ------------------------------------------------------------

if [[ "$EMIT_JSON" -eq 1 ]]; then
    jq -n \
        --arg vr "$VAULT_ROOT" \
        --argjson entries "$(printf '%s\n' "${JSON_ROWS[@]}" | jq -s '.')" \
        '{vault_root:$vr,entries:$entries}'
else
    echo
    echo "vault root:  $VAULT_ROOT"
    echo "config:      $SYNC_JSON"
    echo
    printf '  %-65s %-22s %-10s %-19s\n' "vault_path" "section" "synced" "status"
    printf '  %-65s %-22s %-10s %-19s\n' "----------" "-------" "------" "------"
    for row in "${REPORT_ROWS[@]}"; do
        IFS='|' read -r vp sh sd st tf <<< "$row"
        # Truncate vault_path to keep table readable
        if [[ ${#vp} -gt 65 ]]; then
            vp_display="…${vp: -64}"
        else
            vp_display="$vp"
        fi
        printf '  %-65s %-22s %-10s %-19s\n' "$vp_display" "${sh:0:22}" "$sd" "$st"
    done
    echo
    if [[ "$EXIT_DRIFT" -eq 0 ]]; then
        echo "✓ all entries in-sync"
    else
        echo "drift detected — review and update absorbed content + body_sha256 + synced_at_date"
        echo "  workflow: see docs/syncing-vault.md"
    fi
fi

exit $EXIT_DRIFT
