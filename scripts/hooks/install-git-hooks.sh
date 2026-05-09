#!/usr/bin/env bash
# install-git-hooks.sh — install a local .git/hooks/pre-commit that runs the
# drift detectors before every commit. Closes the asymmetry between Claude's
# PreToolUse hook (which only fires for in-session edits) and direct commits
# from PA's shell after hand-edits in another editor.
#
# Idempotent: re-running overwrites the prior pre-commit only if it carries
# the marker line `# managed-by: organon-plugin install-git-hooks.sh`.
# A user-authored hook is preserved and the installer aborts with rc=2.
#
# Usage:
#   scripts/hooks/install-git-hooks.sh           # install
#   scripts/hooks/install-git-hooks.sh --force   # overwrite even unmanaged hooks
#   scripts/hooks/install-git-hooks.sh --uninstall

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
HOOK_PATH="${REPO_ROOT}/.git/hooks/pre-commit"
MARKER="# managed-by: organon-plugin install-git-hooks.sh"

[[ -d "${REPO_ROOT}/.git" ]] || {
    echo "error: not a git repo: ${REPO_ROOT}" >&2
    exit 2
}

MODE="install"
for arg in "$@"; do
    case "$arg" in
        --force)     MODE="install-force" ;;
        --uninstall) MODE="uninstall" ;;
        -h|--help)
            sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "error: unknown flag: $arg" >&2
            exit 2
            ;;
    esac
done

if [[ "$MODE" == "uninstall" ]]; then
    if [[ -f "$HOOK_PATH" ]] && grep -qF "$MARKER" "$HOOK_PATH"; then
        rm -f "$HOOK_PATH"
        echo "✓ removed managed pre-commit hook"
    else
        echo "no managed pre-commit hook to remove (preserving any user-authored hook)"
    fi
    exit 0
fi

if [[ -f "$HOOK_PATH" && "$MODE" != "install-force" ]]; then
    if ! grep -qF "$MARKER" "$HOOK_PATH"; then
        echo "error: pre-commit hook exists and is not managed by this installer:" >&2
        echo "  $HOOK_PATH" >&2
        echo "re-run with --force to overwrite, or merge manually." >&2
        exit 2
    fi
fi

cat > "$HOOK_PATH" <<'HOOK'
#!/usr/bin/env bash
# managed-by: organon-plugin install-git-hooks.sh
# pre-commit — drift gate + token-presence guard.
# 1. Refuse if .organon-resync-token exists at repo root (a leaked
#    edit-bypass token must never reach a commit).
# 2. Run sync-kepano.sh --no-fetch and sync-vault.sh; block on rc=1
#    (drift), pass through rc≥2 (gate-unavailable) as a warning.
#
# Bypass for an emergency commit: git commit --no-verify

set -u

REPO_ROOT="$(git rev-parse --show-toplevel)"
KEPANO="${REPO_ROOT}/scripts/sync-kepano.sh"
VAULT="${REPO_ROOT}/scripts/sync-vault.sh"
TOKEN="${REPO_ROOT}/.organon-resync-token"

if [[ -f "$TOKEN" ]]; then
    cat <<MSG >&2
✗ Commit blocked: .organon-resync-token exists at repo root.

This token grants Claude a scoped Edit bypass on absorbed-content files
during a re-sync flow. It must be removed before commit. Its presence
implies the resync flow was interrupted before cleanup.

Resolve:
  rm "$TOKEN"
  git commit ...   # the drift gate below will still validate sync correctness

Bypass (use sparingly): git commit --no-verify
MSG
    exit 1
fi

drift=0
warn=0

run_gate() {
    local label="$1" script="$2"
    shift 2
    if [[ ! -x "$script" ]]; then
        echo "  ${label}: script not executable, skipping ($script)"
        return
    fi
    "$script" "$@" >/dev/null 2>&1
    local rc=$?
    case "$rc" in
        0) echo "  ${label}: ✓ in-sync" ;;
        1) echo "  ${label}: ✗ drift detected (rc=1)"; drift=1 ;;
        *) echo "  ${label}: ⚠ gate unavailable rc=${rc}"; warn=1 ;;
    esac
}

echo "organon-plugin pre-commit drift gate:"
run_gate "kepano" "$KEPANO" --no-fetch
run_gate "vault " "$VAULT"

if [[ "$drift" -eq 1 ]]; then
    cat <<MSG

✗ Commit blocked: absorbed-content drift detected.

Resolve before committing:
  - kepano drift → run /kepano-resync (Claude) or scripts/sync-kepano.sh
  - vault  drift → run /vault-resync  (Claude) or follow docs/syncing-vault.md

Bypass (use sparingly): git commit --no-verify
MSG
    exit 1
fi

if [[ "$warn" -eq 1 ]]; then
    echo "  (gate-unavailable warnings are non-blocking; release-readiness will re-check)"
fi
exit 0
HOOK

chmod +x "$HOOK_PATH"
echo "✓ installed managed pre-commit hook → ${HOOK_PATH#${REPO_ROOT}/}"
echo "  bypass with: git commit --no-verify"
echo "  uninstall with: ${BASH_SOURCE[0]#${REPO_ROOT}/} --uninstall"
