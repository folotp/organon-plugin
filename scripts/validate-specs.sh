#!/usr/bin/env bash
# Compatibility entry point for locked shared specification checks.
# Missing dependencies/network are failures; use the documented uv setup remedy.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$root/scripts/dev" specs
