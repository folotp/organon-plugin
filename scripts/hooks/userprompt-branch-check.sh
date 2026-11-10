#!/usr/bin/env bash
# Claude UserPromptSubmit adapter; advisory context only, never a branch switch.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$root/scripts/dev" hook start
