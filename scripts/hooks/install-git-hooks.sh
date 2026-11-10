#!/usr/bin/env bash
# Compatibility entry point for scripts/dev install-hooks [--uninstall].
# The shared installer preserves unmanaged hooks and respects Git worktree paths.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$root/scripts/dev" install-hooks "$@"
