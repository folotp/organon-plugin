#!/usr/bin/env bash
# check-agent-tools.sh — every Organon tool in an agent `tools:` line must be
# listed under both connector prefixes (#106). Subagent allowlists match exact
# names: Code/Desktop mount the connector as mcp__claude_ai_organon__*, claude.ai
# cloud sessions as mcp__organon__*. A missing twin leaves the agent with zero
# Organon tools on that surface.
#
# Usage: scripts/check-agent-tools.sh
# Exit: 0 clean, 1 missing twin(s).
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
status=0

for agent in "$root"/agents/*.md; do
    line="$(sed -n '/^---$/,/^---$/{/^tools:/p;}' "$agent")"
    [ -n "$line" ] || continue
    tools="$(printf '%s\n' "${line#tools:}" | tr ',' '\n' | tr -d ' ')"
    for prefix in mcp__claude_ai_organon__ mcp__organon__; do
        case "$prefix" in
        mcp__claude_ai_organon__) twin=mcp__organon__ ;;
        *) twin=mcp__claude_ai_organon__ ;;
        esac
        while IFS= read -r tool; do
            [ -n "$tool" ] || continue
            name="${tool#"$prefix"}"
            if ! printf '%s\n' "$tools" | grep -qx "${twin}${name}"; then
                echo "${agent#"$root"/}: ${tool} has no ${twin}${name} twin" >&2
                status=1
            fi
        done < <(printf '%s\n' "$tools" | grep "^${prefix}" || true)
    done
done

[ "$status" -eq 0 ] && echo "agent tools: both Organon prefixes listed"
exit "$status"
