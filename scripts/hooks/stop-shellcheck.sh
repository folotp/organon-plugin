#!/usr/bin/env bash
# Advisory feedback; Git/CI run the authoritative checks.
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
"$root/scripts/dev" hook stop || true
