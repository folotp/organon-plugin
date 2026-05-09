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

# Extract the absorbed body inside the matching <!-- VAULT-* --> markers of
# the plugin target file. Skips the boilerplate "<!-- vault-sync: ... -->"
# comment line that immediately follows BEGIN.
#
# The matching key is the vault_path substring on the BEGIN line. Within
# any single target_file, each vault_path is unique (verified across
# vault-sync.json), so substring match is sufficient.
#
# For vault entries, the raw between-markers bytes match the stored
# body_sha256 directly (verified empirically across all 14 entries).
# No further normalization is needed here. (Kepano targets need per-mode
# trimming; that lives in sync-kepano.sh.)
extract_target_marker_body_vault() {
    local target_file="$1"
    local vault_path="$2"
    awk -v vp="$vault_path" '
        BEGIN { in_m = 0; skip_next = 0 }
        index($0, "<!-- VAULT-BEGIN:") == 1 && index($0, vp) > 0 {
            if (!in_m) { in_m = 1; skip_next = 1; next }
        }
        in_m && index($0, "<!-- VAULT-END:") == 1 { exit }
        in_m {
            if (skip_next == 1 && $0 ~ /^<!-- vault-sync:.*-->$/) { skip_next = 0; next }
            skip_next = 0
            print
        }
    ' "$target_file"
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

    # --- Bilateral check: also hash the plugin target's between-markers
    # body and compare to stored_sha256. Catches the silent-corruption
    # case where the absorbed plugin copy is hand-edited (or otherwise
    # diverges from the stored fingerprint) while the live vault still
    # matches stored. The vault-side check above covers the inverse.
    #
    # Vault-side issues take priority: if vault is anything other than
    # in-sync, the routing is to re-extract from vault — which will
    # also overwrite the plugin target — so we report vault-side
    # status. Only when vault is in-sync do we surface target-side
    # statuses (target-corrupt, target-marker-missing, target-file-missing).
    detected_target_sha256=""
    detected_target_status="not-checked"
    target_full_path="${REPO_ROOT}/${target_file}"
    if [[ ! -f "$target_full_path" ]]; then
        detected_target_status="target-file-missing"
    else
        target_body_file="$(mktemp)"
        extract_target_marker_body_vault "$target_full_path" "$vault_path" > "$target_body_file"
        if [[ ! -s "$target_body_file" ]]; then
            detected_target_status="target-marker-missing"
        else
            detected_target_sha256="$(sha256_of < "$target_body_file")"
            if [[ "$detected_target_sha256" == "$stored_sha256" ]]; then
                detected_target_status="in-sync"
            else
                detected_target_status="target-corrupt"
            fi
        fi
        rm -f "$target_body_file"
    fi

    if [[ "$detected_status" == "in-sync" && "$detected_target_status" != "in-sync" ]]; then
        detected_status="$detected_target_status"
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
        --arg dts "$detected_target_sha256" \
        --arg dtss "$detected_target_status" \
        --arg st "$detected_status" \
        --arg tf "$target_file" \
        '{vault_path:$vp,section_heading:$sh,extract_mode:$em,synced_at_date:$sd,stored_sha256:$ss,detected_sha256:$ds,detected_target_sha256:$dts,detected_target_status:$dtss,detected_status:$st,target_file:$tf}')")
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
        # _tf: target_file is stored in the row but not surfaced here.
        IFS='|' read -r vp sh sd st _tf <<< "$row"
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
        echo "✓ all entries in-sync (vault-side AND plugin target verified)"
    else
        echo "drift detected — review and update absorbed content + body_sha256 + synced_at_date"
        echo "  vault-side drift     → re-extract from vault, see /vault-resync"
        echo "  target-corrupt       → plugin target was edited outside the resync flow;"
        echo "                          re-extract from vault to restore"
        echo "  target-marker-missing → markers in plugin target are unreachable; manual fix"
        echo "  workflow: see docs/syncing-vault.md"
    fi
fi

exit $EXIT_DRIFT
