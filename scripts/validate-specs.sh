#!/usr/bin/env bash
# validate-specs.sh — check skills and the plugin manifest against their specs.
#
# Agent Skills: every skills/*/ through the reference validator (skills-ref).
# Agent Plugins 1.0.0: plugin.json against the published schema.
# Dev-only dependency: uv. skills-ref is demonstration-grade upstream, so it's
# a check here and never shipped.
#
# Usage: scripts/validate-specs.sh
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
skills_ref='git+https://github.com/agentskills/agentskills#subdirectory=skills-ref'
schema='https://agent-plugins.org/schemas/1.0.0/plugin.schema.json'

command -v uvx >/dev/null 2>&1 || {
    echo "error: required tool not on PATH: uvx" >&2
    exit 2
}

status=0
for skill in "$root"/skills/*/; do
    uvx -q --from "$skills_ref" skills-ref validate "$skill" || status=1
done
uvx -q check-jsonschema --schemafile "$schema" "$root/plugin.json" || status=1

exit "$status"
