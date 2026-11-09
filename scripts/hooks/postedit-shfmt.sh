#!/usr/bin/env bash
# Advisory formatting feedback using the shared adapter.
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
"$root/scripts/dev" hook format || true
