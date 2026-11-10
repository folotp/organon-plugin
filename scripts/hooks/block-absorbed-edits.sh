#!/usr/bin/env bash
# Claude PreToolUse adapter. Read JSON stdin and propagate shared edit denial (exit 2).
# Policy and path inventory live in scripts/dev.py and config/, not this wrapper.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$root/scripts/dev" hook edit
